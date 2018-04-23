// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTColorTransferProcessor.h"

#import <Accelerate/Accelerate.h>
#import <random>

#import "LT3DLUT.h"
#import "LTColorTransferProcessor+OptimalRotations.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Array of single-precision floats.
typedef std::vector<float> Floats;

/// Array of \c vImagePixelCount representing a 1D histogram.
typedef std::vector<vImagePixelCount> PixelCounts;

@implementation LTColorTransferProcessor

/// Recommended number of pixels for both \c input and \reference for optimal combination of
/// results quality and running time.
static const NSUInteger kRecommendedPixelCount = 500 * 500;

/// Size of the 3D lookup table lattice.
static const NSUInteger kLatticeGridSize = 16;

/// Ratio between the number of samples in the inverse CDF and CDF, in order to achieve a
/// sufficiently close approximate of the inverse function.
static const NSUInteger kInverseCDFScaleFactor = 20;

#pragma mark -
#pragma mark Optimized CPU Processing
#pragma mark -

- (nullable LT3DLUT *)lutForInputTexture:(LTTexture *)input referenceTexture:(LTTexture *)reference
                                progress:(nullable LTColorTransferProgressBlock)progress {
  LTParameterAssert([input.pixelFormat isEqual:$(LTGLPixelFormatRGBA8Unorm)],
                    @"Invalid pixel format for input (%@): must be %@",
                    input.pixelFormat, $(LTGLPixelFormatRGBA8Unorm));
  LTParameterAssert([reference.pixelFormat isEqual:$(LTGLPixelFormatRGBA8Unorm)],
                    @"Invalid pixel format for reference (%@): must be %@",
                    reference.pixelFormat, $(LTGLPixelFormatRGBA8Unorm));

  __block LT3DLUT *lut;
  [input mappedImageForReading:^(const cv::Mat &input, BOOL) {
    [reference mappedImageForReading:^(const cv::Mat &reference, BOOL) {
      lut = [self lutForInputMat:input referenceMat:reference progress:progress];
    }];
  }];

  return lut;
}

- (nullable LT3DLUT *)lutForInputMat:(const cv::Mat4b &)inputMat
                        referenceMat:(const cv::Mat4b &)referenceMat
                            progress:(nullable LTColorTransferProgressBlock)progress {
  const auto pdfSmoothingKernel = [self pdfSmoothingKernel];
  const auto rotations = [self optimalRotations];

  auto input = [self filteredFloatChannelsFromByteMatrix:inputMat];
  auto reference = [self filteredFloatChannelsFromByteMatrix:referenceMat];
  if (!input[0].size() || !reference[0].size()) {
    return nil;
  }

  input = [self replicateFloatChannels:input withNoisyCopies:self.noisyCopies];
  reference = [self replicateFloatChannels:reference withNoisyCopies:self.noisyCopies];

  auto lattice = [self floatChannelsFromLattice:[self identityLattice]];
  auto adjustedLattice = lattice;
  auto adjustedInput = input;

  Floats projectedInput(input[0].size());
  Floats projectedReference(reference[0].size());
  Floats projectedLattice(lattice[0].size());
  Floats adjustedProjectedInput(input[0].size());
  Floats adjustedProjectedLattice(lattice[0].size());

  PixelCounts inputHistogram(self.histogramBins);
  PixelCounts referenceHistogram(self.histogramBins);
  Floats inputCDF(self.histogramBins);
  Floats referenceCDF(self.histogramBins);
  Floats inverseReferenceCDF(self.histogramBins * kInverseCDFScaleFactor);
  Floats auxiliaryCDF(self.histogramBins + pdfSmoothingKernel.size() - 1);

  LT3DLUT * _Nullable lut;
  for (NSUInteger i = 0; i < self.iterations; ++i) {
    [self resetChannels:&adjustedInput toValue:0];
    [self resetChannels:&adjustedLattice toValue:0];

    cv::Mat1f coords = rotations[i];
    for (NSUInteger d = 0; d < input.size(); ++d) {
      auto b = cv::Vec3f(coords((int)d, 0), coords((int)d, 1), coords((int)d, 2));

      [self vectorProjectionOfChannels:input onVector:b target:&projectedInput];
      [self vectorProjectionOfChannels:reference onVector:b target:&projectedReference];
      [self vectorProjectionOfChannels:lattice onVector:b target:&projectedLattice];

      auto inputRange = [self rangeForValues:projectedInput];
      auto referenceRange = [self rangeForValues:projectedReference];
      std::pair<float, float> range(std::min(inputRange.first, referenceRange.first),
                                    std::max(inputRange.second, referenceRange.second));

      [self histogramOfValues:projectedInput range:range target:&inputHistogram];
      [self histogramOfValues:projectedReference range:range target:&referenceHistogram];
      [self cdfForHistogram:inputHistogram target:&inputCDF auxiliary:&auxiliaryCDF
         pdfSmoothingKernel:pdfSmoothingKernel];
      [self cdfForHistogram:referenceHistogram target:&referenceCDF auxiliary:&auxiliaryCDF
         pdfSmoothingKernel:pdfSmoothingKernel];
      [self inverseCDF:referenceCDF range:range target:&inverseReferenceCDF];

      [self histogramSpecificationOnInput:projectedInput inputCDF:inputCDF
                      inverseReferenceCDF:inverseReferenceCDF range:range
                                   target:&adjustedProjectedInput];
      [self histogramSpecificationOnInput:projectedLattice inputCDF:inputCDF
                      inverseReferenceCDF:inverseReferenceCDF range:range
                                   target:&adjustedProjectedLattice];

      [self scalarProjectionOfScalars:adjustedProjectedInput onVector:b target:&adjustedInput];
      [self scalarProjectionOfScalars:adjustedProjectedLattice onVector:b target:&adjustedLattice];
    }

    for (NSUInteger d = 0; d < input.size(); ++d) {
      float a = 1 - self.dampingFactor;
      float b = self.dampingFactor;
      vDSP_vsmsma(input[d].data(), 1, &a, adjustedInput[d].data(), 1, &b,
                  input[d].data(), 1, input[d].size());
      vDSP_vsmsma(lattice[d].data(), 1, &a, adjustedLattice[d].data(), 1, &b,
                  lattice[d].data(), 1, lattice[d].size());
    }

    if (progress) {
      lut = [self lutFromFloatChannels:lattice];
      progress(i + 1, lut);
    }
  }

  return lut ?: [self lutFromFloatChannels:lattice];
}

- (std::vector<Floats>)filteredFloatChannelsFromByteMatrix:(const cv::Mat4b &)mat {
  auto byteChannels = [self filteredByteChannelsFromMatrix:mat];
  auto size = byteChannels[0].size();

  std::vector<Floats> channels = {Floats(size), Floats(size), Floats(size)};
  if (!size) {
    return channels;
  }

  for (NSUInteger dimension = 0; dimension < channels.size(); ++dimension) {
    vDSP_vfltu8(byteChannels[dimension].data(), 1, channels[dimension].data(), 1, size);
  }

  float scale = 1.0 / 255.0;
  for (NSUInteger dimension = 0; dimension < channels.size(); ++dimension) {
    vDSP_vsmul(channels[dimension].data(), 1, &scale,
               channels[dimension].data(), 1, channels[dimension].size());
  }

  return channels;
}

- (std::vector<std::vector<uchar>>)filteredByteChannelsFromMatrix:(const cv::Mat4b &)mat {
  std::vector<cv::Vec4b> filtered(mat.total());
  uchar threshold = std::round(self.alphaThreshold * std::numeric_limits<uchar>::max());
  auto last = std::copy_if(mat.begin(), mat.end(), filtered.begin(), [threshold](cv::Vec4b v) {
    return v[3] >= threshold;
  });

  size_t numPixels = last - filtered.begin();
  std::vector<std::vector<uchar>> channels = {
    std::vector<uchar>(numPixels), std::vector<uchar>(numPixels), std::vector<uchar>(numPixels)
  };
  for (NSUInteger i = 0; i < numPixels; ++i) {
    auto v = filtered[i];
    channels[0][i] = v[0];
    channels[1][i] = v[1];
    channels[2][i] = v[2];
  }

  return channels;
}

- (std::vector<Floats>)replicateFloatChannels:(const std::vector<Floats> &)channels
                              withNoisyCopies:(NSUInteger)noisyCopies {
  auto engine = std::default_random_engine(0);
  std::normal_distribution<float> distribution(0, self.noiseStandardDeviation);

  std::vector<Floats> replicatedChannels(channels.size());
  for (NSUInteger d = 0; d < channels.size(); ++d) {
    auto numElements = channels[d].size();
    replicatedChannels[d].resize(numElements * (noisyCopies + 1));
    for (NSUInteger i = 0; i < noisyCopies + 1; ++i) {
        std::transform(channels[d].begin(), channels[d].end(),
                       replicatedChannels[d].begin() + i * numElements,
                       [i, &distribution, &engine](float v) {
          return i == 0 ? v : v + distribution(engine);
        });
    }
  }

  return replicatedChannels;
}

- (std::vector<Floats>)floatChannelsFromLattice:(const cv::Mat3f &)lattice {
  std::vector<cv::Mat1f> channels;
  cv::split(lattice, channels);

  std::vector<Floats> latticeChannels(channels.size());
  for (NSUInteger d = 0; d < channels.size(); ++d) {
    latticeChannels[d].assign(channels[d].begin(), channels[d].end());
  }

  return latticeChannels;
}

- (const cv::Mat3f)identityLattice {
  static cv::Mat3f lattice;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
    lattice.create(3, latticeDims);
    for (int b = 0; b < (int)kLatticeGridSize; ++b) {
      for (int g = 0; g < (int)kLatticeGridSize; ++g) {
        for (int r = 0; r < (int)kLatticeGridSize; ++r) {
          cv::Vec3f &rgbColor = lattice(b, g, r);
          rgbColor[0] = ((float)r) / (kLatticeGridSize - 1);
          rgbColor[1] = ((float)g) / (kLatticeGridSize - 1);
          rgbColor[2] = ((float)b) / (kLatticeGridSize - 1);
        }
      }
    }
  });

  return lattice.clone();
}

- (LT3DLUT *)lutFromFloatChannels:(const std::vector<Floats > &)channels {
  auto lattice = [self latticeFromFloatChannels:channels];
  auto byteLattice = [self byteLatticeFromFloatLattice:lattice];
  return [[LT3DLUT alloc] initWithLatticeMat:byteLattice];
}

- (cv::Mat3f)latticeFromFloatChannels:(const std::vector<Floats> &)channels {
  int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
  std::vector<cv::Mat1f> latticeChannels(channels.size());
  for (NSUInteger d = 0; d < channels.size(); ++d) {
    latticeChannels[d].create(3, latticeDims);
    std::copy(channels[d].begin(), channels[d].end(), latticeChannels[d].begin());
  }

  cv::Mat3f lattice;
  cv::merge(latticeChannels, lattice);
  return lattice;
}

- (void)resetChannels:(std::vector<Floats> *)channels toValue:(float)value {
  for (auto &vector : *channels) {
    catlas_sset((int)vector.size(), value, vector.data(), 1);
  }
}

- (void)vectorProjectionOfChannels:(const std::vector<Floats> &)channels
                          onVector:(const cv::Vec3f &)vector target:(Floats *)target {
  LTParameterAssert(channels.size() == vector.channels,
                    @"Number of channels (%lu) must match vector elements (%du)",
                    channels.size(), vector.channels);

  catlas_sset((int)target->size(), 0, target->data(), 1);

  for (int d = 0; d < vector.channels; ++d) {
    LTParameterAssert(channels[d].size() == target->size(),
                      @"Size of channel[%d] (%lu) must match size of target (%lu)",
                      d, channels[d].size(), target->size());
    float scalar = vector[d];
    vDSP_vsma(channels[d].data(), 1, &scalar, target->data(), 1, target->data(), 1, target->size());
  }
}

- (void)scalarProjectionOfScalars:(const Floats &)scalars onVector:(const cv::Vec3f &)vector
                           target:(std::vector<Floats> *)target {
  LTParameterAssert(target->size() == vector.channels,
                    @"Number of target channels (%lu) must match vector elements (%du)",
                    target->size(), vector.channels);

  for (int d = 0; d < vector.channels; ++d) {
    LTParameterAssert(scalars.size() == (*target)[d].size(),
                      @"Size of scalars (%lu) must match target channel[%d] size (%lu)",
                      scalars.size(), d, (*target)[d].size());
    float baseElement = vector[d];
    vDSP_vsma(scalars.data(), 1, &baseElement, (*target)[d].data(), 1,
              (*target)[d].data(), 1, scalars.size());
  }
}

- (std::pair<float, float>)rangeForValues:(const Floats &)values {
  float minValue;
  float maxValue;
  vDSP_minv(values.data(), 1, &minValue, values.size());
  vDSP_maxv(values.data(), 1, &maxValue, values.size());
  return {minValue, maxValue};
}

- (void)histogramOfValues:(const Floats &)values range:(std::pair<float, float>)range
                   target:(PixelCounts *)target {
  vImage_Buffer vBuffer = {
    .data = (void *)values.data(),
    .height = 1,
    .width = values.size(),
    .rowBytes = values.size() * sizeof(values[0])
  };

  vImageHistogramCalculation_PlanarF(&vBuffer, target->data(), (unsigned int)target->size(),
                                     range.first, range.second, 0);
}

- (void)cdfForHistogram:(const PixelCounts &)histogram target:(Floats *)target
              auxiliary:(Floats *)auxiliary pdfSmoothingKernel:(const Floats &)pdfSmoothingKernel {
  LTParameterAssert(histogram.size() == target->size(),
                    @"Size of histogram (%lu) must match size of target (%lu)",
                    histogram.size(), target->size());
  LTParameterAssert(auxiliary->size() == histogram.size() + pdfSmoothingKernel.size() - 1,
                    @"Invalid auxiliary buffer size (%lu): must equal size of histogram (%lu) + "
                    "size of smoothing kernel (%lu) - 1",
                    auxiliary->size(), histogram.size(), pdfSmoothingKernel.size());

  auto smoothKernelRadius = pdfSmoothingKernel.size() / 2;
  vImagePixelCount totalPixels = 0;

  catlas_sset((int)auxiliary->size(), 0, auxiliary->data(), 1);
  std::transform(histogram.begin(), histogram.end(),
                 auxiliary->begin() + smoothKernelRadius, [&totalPixels](auto pixelCount) {
    totalPixels += pixelCount;
    return (float)pixelCount;
  });

  float scale = 1.0 / totalPixels;
  vDSP_vsmul(auxiliary->data(), 1, &scale, auxiliary->data(), 1, auxiliary->size());

  vDSP_conv(auxiliary->data(), 1, pdfSmoothingKernel.data(), 1, target->data(), 1, target->size(),
            pdfSmoothingKernel.size());

  float firstValue = (*target)[0];
  float scalar = 1;
  vDSP_vrsum(target->data(), 1, &scalar, target->data(), 1, target->size());
  vDSP_vsadd(target->data(), 1, &firstValue, target->data(), 1, target->size());
}

- (void)inverseCDF:(const Floats &)cdf range:(std::pair<float, float>)range
            target:(Floats *)target {
  auto rangeLength = range.second - range.first;

  for (NSUInteger i = 0; i < target->size(); ++i) {
    float v = (float)i / (target->size() - 1);

    float minIndex = cdf.size() - 1;
    for (NSUInteger j = 0; j < cdf.size(); ++j) {
      if (cdf[j] > v) {
        if (j == 0) {
          minIndex = j;
        } else {
          float a = cdf[j - 1];
          float b = cdf[j];
          float alpha = (v - a) / (b - a);
          minIndex = j - 1 + alpha;
        }
        break;
      }
    }

    auto index = (float)minIndex / (cdf.size() - 1);
    (*target)[i] = range.first + index * rangeLength;
  }
}

- (void)histogramSpecificationOnInput:(const Floats &)input inputCDF:(const Floats &)inputCDF
                  inverseReferenceCDF:(const Floats &)inverseReferenceCDF
                                range:(std::pair<float, float>)range target:(Floats *)target {
  LTParameterAssert(input.size() == target->size(),
                    @"Size of input (%lu) must match size of target (%lu)",
                    input.size(), target->size());
  auto rangeLength = range.second - range.first;

  float srcCDFBinScale = (inputCDF.size() - 1) / rangeLength;
  float srcCDFBinOffset = -range.first * srcCDFBinScale;
  vDSP_vtabi(input.data(), 1, &srcCDFBinScale, &srcCDFBinOffset, inputCDF.data(), inputCDF.size(),
             target->data(), 1, input.size());

  float inverseRefCDFBinScale = inverseReferenceCDF.size() - 1;
  float inverseRefCDFBinOffset = 0;
  vDSP_vtabi(target->data(), 1, &inverseRefCDFBinScale, &inverseRefCDFBinOffset,
             inverseReferenceCDF.data(), inverseReferenceCDF.size(),
             target->data(), 1, target->size());
}

- (cv::Mat4b)byteLatticeFromFloatLattice:(const cv::Mat3f &)lattice {
  int latticeDims[] = {kLatticeGridSize, kLatticeGridSize, kLatticeGridSize};
  cv::Mat4b byteLattice(3, latticeDims);
  std::transform(lattice.begin(), lattice.end(), byteLattice.begin(), [](const cv::Vec3f &v) {
    return (cv::Vec4b)std::clamp(LTVector4(v[0], v[1], v[2], 1), 0, 1);
  });
  return byteLattice;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(NSUInteger, iterations, Iterations, 1, 50, 20);
LTProperty(NSUInteger, histogramBins, HistogramBins, 2, 255, 32);
LTProperty(float, alphaThreshold, AlphaThreshold, 0, 1, 0.5);
LTProperty(float, dampingFactor, DampingFactor, 0, 1, 0.2);
LTProperty(NSUInteger, noisyCopies, NoisyCopies, 0, 5, 1);
LTProperty(float, noiseStandardDeviation, NoiseStandardDeviation, 0,
           std::numeric_limits<float>::max(), 0.1);

+ (NSUInteger)recommendedNumberOfPixels {
  return kRecommendedPixelCount;
}

- (const Floats)pdfSmoothingKernel {
  static cv::Mat1f kernel;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kernel = cv::getGaussianKernel(7, 1);
  });

  return Floats(kernel.begin(), kernel.end());
}

@end

@interface LTColorTransferProcessor (ForTesting)

@property (class, readonly, nonatomic) NSUInteger inverseCDFScaleFactor;
@property (class, readonly, nonatomic) NSUInteger latticeGridSize;

@end

@implementation LTColorTransferProcessor (ForTesting)

+ (NSUInteger)inverseCDFScaleFactor {
  return kInverseCDFScaleFactor;
}

+ (NSUInteger)latticeGridSize {
  return kLatticeGridSize;
}

@end

NS_ASSUME_NONNULL_END
