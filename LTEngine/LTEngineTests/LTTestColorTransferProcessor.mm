// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTestColorTransferProcessor.h"

#import <Accelerate/Accelerate.h>

#pragma push_macro("equal")
#undef equal
#import <random>
#pragma pop_macro("equal")

#import "LT3DLUT.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Array of single-precision floats.
typedef std::vector<float> Floats;

/// Array of \c vImagePixelCount representing a 1D histogram.
typedef std::vector<vImagePixelCount> PixelCounts;

@interface LTColorTransferProcessor ()

- (Floats)pdfSmoothingKernel;
- (std::vector<cv::Mat1f>)optimalRotations;
- (cv::Mat4b)byteLatticeFromFloatLattice:(const cv::Mat3f &)lattice;
- (cv::Mat3f)identityLattice;
- (void)inverseCDF:(const Floats &)cdf range:(std::pair<float, float>)range target:(Floats *)target;
- (void)histogramOfValues:(const Floats &)values range:(std::pair<float, float>)range
                   target:(PixelCounts *)target;

@property (class, readonly, nonatomic) NSUInteger latticeGridSize;
@property (class, readonly, nonatomic) NSUInteger inverseCDFScaleFactor;

@end

@implementation LTTestColorTransferProcessor

- (nullable LT3DLUT *)lutForInputMat:(const cv::Mat4b &)inputMat
                        referenceMat:(const cv::Mat4b &)referenceMat
                            progress:(nullable LTColorTransferProgressBlock)progress {
  const auto rotations = [super optimalRotations];
  const auto pdfSmoothingKernel = [super pdfSmoothingKernel];

  cv::Mat3f input = [self floatMatrixFromByteMatrix:inputMat];
  cv::Mat3f reference = [self floatMatrixFromByteMatrix:referenceMat];

  input = [self matWithRegularizationCopiesFromMat:input];
  reference = [self matWithRegularizationCopiesFromMat:reference];

  cv::Mat3f lattice = [self identityLattice];
  cv::Mat3f adjustedLattice = lattice.clone();
  cv::Mat3f adjustedInput = cv::Mat3f::zeros(input.size());

  Floats projectedInput(input.total());
  Floats projectedReference(reference.total());
  Floats projectedLattice(lattice.total());
  Floats adjustedProjectedInput(input.total());
  Floats adjustedProjectedLattice(lattice.total());

  PixelCounts inputHistogram(self.histogramBins);
  PixelCounts referenceHistogram(self.histogramBins);
  Floats inputCDF(self.histogramBins);
  Floats referenceCDF(self.histogramBins);
  Floats inverseReferenceCDF(self.histogramBins * LTColorTransferProcessor.inverseCDFScaleFactor);
  Floats auxiliaryCDF(self.histogramBins + pdfSmoothingKernel.size() - 1);

  LT3DLUT * _Nullable lut;
  for (NSUInteger i = 0; i < self.iterations; ++i) {
    adjustedLattice.setTo(cv::Vec3f(0, 0, 0));
    adjustedInput.setTo(cv::Vec3f(0, 0, 0));

    cv::Mat1f coords = rotations[i];
    for (int d = 0; d < 3; ++d) {
      auto b = cv::Vec3f(coords(d, 0), coords(d, 1), coords(d, 2));

      std::transform(input.begin(), input.end(), projectedInput.begin(), [b](cv::Vec3f v) {
        return v.dot(b);
      });
      std::transform(reference.begin(), reference.end(), projectedReference.begin(),
                     [b](cv::Vec3f v) {
        return v.dot(b);
      });
      std::transform(lattice.begin(), lattice.end(), projectedLattice.begin(), [b](cv::Vec3f v) {
        return v.dot(b);
      });

      auto inputRange = [self rangeForValues:projectedInput];
      auto referenceRange = [self rangeForValues:projectedReference];
      std::pair<float, float> range(std::min(inputRange.first, referenceRange.first),
                                    std::max(inputRange.second, referenceRange.second));

      [self histogramOfValues:projectedInput range:range target:&inputHistogram];
      [self histogramOfValues:projectedReference range:range target:&referenceHistogram];
      [self cdfForHistogram:inputHistogram target:&inputCDF auxiliary:&auxiliaryCDF];
      [self cdfForHistogram:referenceHistogram target:&referenceCDF auxiliary:&auxiliaryCDF];
      [self inverseCDF:referenceCDF range:range target:&inverseReferenceCDF];

      [self histogramSpecificationOnInput:projectedInput inputCDF:inputCDF
                      inverseReferenceCDF:inverseReferenceCDF range:range
                                   target:&adjustedProjectedInput];
      [self histogramSpecificationOnInput:projectedLattice inputCDF:inputCDF
                      inverseReferenceCDF:inverseReferenceCDF range:range
                                   target:&adjustedProjectedLattice];

      std::transform(adjustedProjectedLattice.begin(), adjustedProjectedLattice.end(),
                     adjustedLattice.begin(), adjustedLattice.begin(), [b](float f, cv::Vec3f v) {
        return v + f * b;
      });
      std::transform(adjustedProjectedInput.begin(), adjustedProjectedInput.end(),
                     adjustedInput.begin(), adjustedInput.begin(), [b](float f, cv::Vec3f v) {
        return v + f * b;
      });
    }

    auto dampingFactor = self.dampingFactor;
    std::transform(input.begin(), input.end(), adjustedInput.begin(), input.begin(),
                   [dampingFactor](cv::Vec3f a, cv::Vec3f b) {
      return (1 - dampingFactor) * a + dampingFactor * b;
    });

    std::transform(lattice.begin(), lattice.end(), adjustedLattice.begin(), lattice.begin(),
                   [dampingFactor](cv::Vec3f a, cv::Vec3f b) {
      return (1 - dampingFactor) * a + dampingFactor * b;
    });

    if (progress) {
      lut = [[LT3DLUT alloc] initWithLatticeMat:[self byteLatticeFromFloatLattice:lattice]];
      progress(i + 1, lut);
    }
  }

  return lut ?: [[LT3DLUT alloc] initWithLatticeMat:[self byteLatticeFromFloatLattice:lattice]];
}

- (cv::Mat)floatMatrixFromByteMatrix:(const cv::Mat4b &)mat {
  cv::Mat4f floatMatrix(mat.size());

  float scale = 1.0 / 255.0;
  int rowSize = mat.cols * mat.channels();
  for (int rowIndex = 0; rowIndex < mat.rows; ++rowIndex) {
    vDSP_vfltu8(mat.ptr<uchar>(rowIndex), 1, floatMatrix.ptr<float>(rowIndex), 1, rowSize);
    vDSP_vsmul(floatMatrix.ptr<float>(rowIndex), 1, &scale, floatMatrix.ptr<float>(rowIndex), 1,
               rowSize);
  }

  std::vector<cv::Mat> channels;
  cv::split(floatMatrix, channels);
  channels.pop_back();

  cv::Mat3f rgbFloatMatrix;
  cv::merge(channels, rgbFloatMatrix);
  LTAssert(rgbFloatMatrix.isContinuous());
  return rgbFloatMatrix;
}

- (cv::Mat)matWithRegularizationCopiesFromMat:(const cv::Mat3f &)mat {
  cv::Mat3f matWithCopies(mat.rows * (int)(self.noisyCopies + 1), mat.cols);

  // Seed is fixed since we don't need nor want this to generate a different sequence between calls.
  auto engine = std::default_random_engine(0);
  std::normal_distribution<float> distribution(0, self.noiseStandardDeviation);

  for (NSUInteger i = 0; i < self.noisyCopies + 1; ++i) {
    std::transform(mat.begin(), mat.end(), matWithCopies.begin() + i * mat.total(),
                   [i, &distribution, &engine](const auto &v) {
      return i == 0 ?
          v : v + cv::Vec3f(distribution(engine), distribution(engine), distribution(engine));
    });
  }

  return matWithCopies;
}

- (std::pair<float, float>)rangeForValues:(const Floats &)values {
  auto minmax_elements = std::minmax_element(values.begin(), values.end());
  return std::pair<float, float>(*minmax_elements.first, *minmax_elements.second);
}

- (void)cdfForHistogram:(const PixelCounts &)histogram target:(Floats *)target
              auxiliary:(Floats *)auxiliary {
  auto pdfSmoothingKernel = [super pdfSmoothingKernel];

  LTParameterAssert(histogram.size() == target->size());
  LTParameterAssert(auxiliary->size() == histogram.size() + pdfSmoothingKernel.size() - 1);

  auto totalPixels = std::accumulate(histogram.begin(), histogram.end(), 0);
  auto smoothKernelRadius = pdfSmoothingKernel.size() / 2;

  std::fill(auxiliary->begin(), auxiliary->end(), 0);
  std::transform(histogram.begin(), histogram.end(), auxiliary->begin() + smoothKernelRadius,
                 [totalPixels](auto count) {
    return (float)count / totalPixels;
  });

  vDSP_conv(auxiliary->data(), 1, pdfSmoothingKernel.data(), 1, target->data(), 1, target->size(),
            pdfSmoothingKernel.size());

  std::partial_sum(target->begin(), target->end(), target->begin());
}

- (void)histogramSpecificationOnInput:(const Floats &)input
                             inputCDF:(const Floats &)inputCDF
                  inverseReferenceCDF:(const Floats &)inverseReferenceCDF
                                range:(std::pair<float, float>)range
                               target:(Floats *)target {
  auto rangeLength = range.second - range.first;
  std::transform(input.begin(), input.end(), target->begin(),
                 [inverseReferenceCDF, inputCDF, range, rangeLength](float v) {
    // Sample the lookup table with linear interpolation when the offset is not an integer.
    // see https://developer.apple.com/documentation/accelerate/1450762-vdsp_vtabi.
    float srcCDFBin = std::clamp((v - range.first) / rangeLength, 0.f, 1.f) * (inputCDF.size() - 1);
    float alpha = srcCDFBin - std::floor(srcCDFBin);
    float srcCDFValue = (1 - alpha) * inputCDF[std::floor(srcCDFBin)] +
        alpha * inputCDF[std::ceil(srcCDFBin)];

    float inverseRefCDFBin = std::clamp(srcCDFValue, 0.f, 1.f) * (inverseReferenceCDF.size() - 1);
    alpha = inverseRefCDFBin - std::floor(inverseRefCDFBin);
    return (1 - alpha) * inverseReferenceCDF[std::floor(inverseRefCDFBin)] +
        alpha * inverseReferenceCDF[std::ceil(inverseRefCDFBin)];
  });
}

@end

NS_ASSUME_NONNULL_END
