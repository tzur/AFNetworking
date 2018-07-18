// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionTreeTipMovement.h"

#import <Accelerate/Accelerate.h>
#import <LTEngine/LTSplitComplexMat.h>

NS_ASSUME_NONNULL_BEGIN

@interface PNKImageMotionTreeTipMovement ()

/// Number of time samples used to simulate the movement of a tree tip.
@property (readonly, nonatomic) NSUInteger numberOfSamples;

@end

@implementation PNKImageMotionTreeTipMovement {
  /// Displacements of a tree tip with different random seeds.
  cv::Mat1f _treeTipDisplacements;
}

- (instancetype)initWithNumberOfSamples:(NSUInteger)numberOfSamples {
  float integralPart;
  LTParameterAssert(std::modf(std::log2(numberOfSamples), &integralPart) < 1.e-7,
                    @"numberOfSamples should be a power of 2, got: %lu",
                    (unsigned long)numberOfSamples);
  if (self = [super init]) {
    _numberOfSamples = numberOfSamples;
    [self setupTipMotion];
  }
  return self;
}

- (void)setupTipMotion {
  static const NSUInteger kDisplacementsCount = 10;
  _treeTipDisplacements = cv::Mat1f((int)kDisplacementsCount, (int)self.numberOfSamples);

  float numberOfSamplesLog = std::log2(self.numberOfSamples);
  FFTSetup fftSetup = vDSP_create_fftsetup((int)numberOfSamplesLog, kFFTRadix2);

  for (int i = 0; i < (int)kDisplacementsCount; ++i) {
    auto displacement = [self tipDisplacementInSpatialSpaceWithFFTSetup:fftSetup];
    double norm = cv::norm(displacement, cv::NORM_INF);
    displacement /= norm;
    displacement.copyTo(_treeTipDisplacements.row(i));
  }

  vDSP_destroy_fftsetup(fftSetup);
}

- (cv::Mat1f)tipDisplacementInSpatialSpaceWithFFTSetup:(FFTSetup)fftSetup {
  auto tipDisplacementInFrequencySpace = [self tipDisplacementInFrequencySpace];

  DSPSplitComplex frequencyData = {
    (float *)tipDisplacementInFrequencySpace.real.data,
    (float *)tipDisplacementInFrequencySpace.imag.data
  };

  cv::Mat1f spatialReal(1, (int)self.numberOfSamples);
  cv::Mat1f spatialImaginary(1, (int)self.numberOfSamples);

  DSPSplitComplex spatialData = {
    (float *)spatialReal.data,
    (float *)spatialImaginary.data
  };

  auto numberOfSamplesLog = (vDSP_Length)std::log2(self.numberOfSamples);

  vDSP_fft_zop(fftSetup, &frequencyData, 1, &spatialData, 1, numberOfSamplesLog,
               kFFTDirection_Inverse);

  return spatialReal;
}

- (LTSplitComplexMat *)tipDisplacementInFrequencySpace {
  static const NSUInteger kFramesPerSecond = 30;
  static const CGFloat kGamma = 1;
  static const CGFloat kKappa = 1;
  static const CGFloat kNaturalFrequency = 0.5;
  static const CGFloat kNaturalFrequencySquare = kNaturalFrequency * kNaturalFrequency;
  static const CGFloat kMass = 1;
  static const CGFloat kMeanWindSpeed = 1;
  static const std::complex<double> kI(0, 1);

  static cv::RNG randomNumbersGenerator(10000);

  float seconds = ((float)self.numberOfSamples) / ((float)kFramesPerSecond);
  float nyquistFrequency = (1. / seconds) * 2;

  cv::Mat1f real(1, (int)self.numberOfSamples);
  cv::Mat1f imag(1, (int)self.numberOfSamples);

  for (int i = 0; i < (int)self.numberOfSamples; ++i) {
    double frequency = (i - (int)self.numberOfSamples / 2) * nyquistFrequency;
    double xsi = randomNumbersGenerator.gaussian(1.0);
    double phi = randomNumbersGenerator.uniform(0., 2 * M_PI);
    std::complex<double> windVelocityInFrequencySpace = (double)kMeanWindSpeed /
        std::pow(std::complex<double>(1 + kKappa * frequency / kMeanWindSpeed, 0), 5. / 3.);

    std::complex<double> velocityRandomField = xsi * std::exp(std::complex<double>(0, phi)) *
        std::sqrt(windVelocityInFrequencySpace);

    double tanTheta = kGamma * frequency / (2 * M_PI * (frequency * frequency -
                                                        kNaturalFrequencySquare));
    double theta = std::atan(tanTheta);

    auto displacementInFrequencySpace = velocityRandomField * std::exp(2. * kI * M_PI * theta) /
        std::sqrt(std::pow(2 * M_PI * (frequency * frequency - kNaturalFrequencySquare), 2) +
                  kGamma * kGamma * frequency * frequency) / (2 * M_PI * kMass);

    int index = (i + (int)self.numberOfSamples / 2) % (int)self.numberOfSamples;
    real.at<float>(0, index) = displacementInFrequencySpace.real();
    imag.at<float>(0, index) = displacementInFrequencySpace.imag();
  }

  return [[LTSplitComplexMat alloc] initWithReal:real imag:imag];
}

- (cv::Mat1f)treeTipDisplacements {
  return _treeTipDisplacements;
}

@end

NS_ASSUME_NONNULL_END
