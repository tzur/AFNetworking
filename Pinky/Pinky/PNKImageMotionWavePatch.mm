// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionWavePatch.h"

#import <LTEngine/LTFFTProcessor.h>
#import <LTEngine/LTSplitComplexMat.h>

NS_ASSUME_NONNULL_BEGIN

/// Gravitational constant.
static const float kGravitationalConstant = 9.8;

static float PNKPhillipsSpectrum(float spatialFrequencyX, float spatialFrequencyY,
                                 float windVelocityX, float windVelocityY) {
  float spatialFrequencyNormSquare = spatialFrequencyX * spatialFrequencyX +
      spatialFrequencyY * spatialFrequencyY + 1.e-8;

  float windVelocityNormSquare =
      windVelocityX * windVelocityX + windVelocityY * windVelocityY + 1.e-8;

  float scalarProduct = spatialFrequencyX * windVelocityX + spatialFrequencyY * windVelocityY;
  float angleCosineSquare = (scalarProduct * scalarProduct) /
      (spatialFrequencyNormSquare * windVelocityNormSquare);

  float waveAmplitude = windVelocityNormSquare / kGravitationalConstant;

  return std::exp(-1 / (spatialFrequencyNormSquare * waveAmplitude * waveAmplitude)) *
      angleCosineSquare / (spatialFrequencyNormSquare * spatialFrequencyNormSquare);
}

static std::complex<float> PNKH0Cell(float spatialFrequencyX, float spatialFrequencyY) {
  static cv::RNG randomNumbersGenerator;

  float xsi = randomNumbersGenerator.gaussian(1.0);
  float theta = randomNumbersGenerator.uniform(0., 2 * M_PI);
  return xsi * std::exp(std::complex<float>(0, theta)) *
      std::sqrt(PNKPhillipsSpectrum(spatialFrequencyX, spatialFrequencyY, 0, 1));
}

static cv::Mat2f PNKH0Matrix(int rows, int cols) {
  cv::Mat2f h0(rows, cols);
  for (int row = 0; row < rows; ++row) {
    for (int col = 0; col < cols; ++col) {
      std::complex<float> value = PNKH0Cell(col - cols / 2, row - rows / 2);
      h0.at<cv::Vec2f>(row, col)[0] = value.real();
      h0.at<cv::Vec2f>(row, col)[1] = value.imag();
    }
  }

  return h0;
}

static cv::Mat1f PNKHtMatrix(const cv::Mat2f &h0, float t) {
  auto rows = h0.rows;
  auto cols = h0.cols;

  cv::Mat1f ht(rows, cols);

  for (int row = 0; row < rows; ++row) {
    for (int col = 0; col < cols; ++col) {
      float x = col - cols / 2;
      float y = row - rows / 2;
      auto w = std::sqrt(kGravitationalConstant * std::sqrt(x * x + y * y));
      auto rotation = std::exp(std::complex<float>(0, w * t));

      auto h0Value = std::complex<float>(h0(row, col)[0], h0(row, col)[1]);
      ht.at<float>(row, col) = 2 * (h0Value * rotation).real();
    }
  }

  return ht;
}

@interface PNKImageMotionWavePatch ()

/// Patch size.
@property (readonly, nonatomic) NSUInteger patchSize;

/// Processor that performs FFT transforms.
@property (readonly, nonatomic) LTFFTProcessor *fftProcessor;

/// Split complex matrix storing the FFT output.
@property (readonly, nonatomic) LTSplitComplexMat *spatial;

@end

@implementation PNKImageMotionWavePatch {
  cv::Mat2f _h0;
  cv::Mat1f _frequencyReal;
}

- (instancetype)initWithPatchSize:(NSUInteger)patchSize {
  if (self = [super init]) {
    _patchSize = patchSize;
    _h0 = PNKH0Matrix((int)patchSize, (int)patchSize);

    float patchSizeLog = std::log2(patchSize);
    LTParameterAssert(patchSizeLog - (int)patchSizeLog < 1.e-7, @"Patch size should be a power of "
                      "2, got: %lu", (unsigned long)patchSize);

    _frequencyReal = cv::Mat1f((int)patchSize, (int)patchSize);
    _spatial = [[LTSplitComplexMat alloc] initWithReal:cv::Mat1f((int)patchSize, (int)patchSize)
                                                  imag:cv::Mat1f((int)patchSize, (int)patchSize)];
    _fftProcessor = [[LTFFTProcessor alloc] initWithRealInput:_frequencyReal output:_spatial];
    self.fftProcessor.transformDirection = LTFFTTransformDirectionInverse;
  }
  return self;
}

- (const cv::Mat &)displacementsForTime:(NSTimeInterval)time {
  [self updateFrequencyRealWithTime:time];
  [self performFFT];
  return _spatial.real;
}

- (void)updateFrequencyRealWithTime:(NSTimeInterval)time {
  auto ht = PNKHtMatrix(_h0, time);

  auto rows = ht.rows;
  auto cols = ht.cols;

  for (int row = 0; row < rows; ++row) {
    for (int col = 0; col < cols; ++col) {
      float shiftedRow = (row < rows / 2) ? (row + rows / 2) : (row - rows / 2);
      float shiftedCol = (col < cols / 2) ? (col + cols / 2) : (col - cols / 2);
      _frequencyReal.at<float>(row, col) = ht(shiftedRow, shiftedCol);
    }
  }
}

- (void)performFFT {
  [self.fftProcessor process];
}

@end

NS_ASSUME_NONNULL_END
