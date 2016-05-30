// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTConsistentGaussianFilterProcessor.h"

#import "LTGaussianConvolutionDivider.h"
#import "LTGaussianFilterProcessor.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTConsistentGaussianFilterSpatialUnitProvider
#pragma mark -

/// Sets spatial unit so that the largest image dimension will be of <tt>length = 1</tt> when
/// calculating the gaussian value if the input and output images size match.
@interface LTConsistentGaussianFilterSpatialUnitProvider :
    NSObject <LTGaussianFilterSpatialUnitProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the spatial unit provider with the size of input image.
- (instancetype)initWithInputSize:(CGSize)inputSize NS_DESIGNATED_INITIALIZER;

/// Input image size.
@property (readonly, nonatomic) CGSize inputSize;

@end

@implementation LTConsistentGaussianFilterSpatialUnitProvider

- (instancetype)initWithInputSize:(CGSize)inputSize {
  if (self = [super init]) {
    _inputSize = inputSize;
  }
  return self;
}

- (CGFloat)spatialUnitForImageSize:(CGSize)size {
  return (self.inputSize.width / size.width) / std::max(size.width, size.height);
}

@end

#pragma mark -
#pragma mark LTConsistentGaussianFilterProcessor
#pragma mark -

@interface LTConsistentGaussianFilterProcessor ()

/// Gaussian filter processor that is used to actually apply the blur.
@property (readonly, nonatomic) LTGaussianFilterProcessor *internalProcessor;

// Spatial unit provider used by \c internalProcessor
@property (readonly, nonatomic) LTConsistentGaussianFilterSpatialUnitProvider *spatialUnitProvider;

@end

// (1.0 - is 68%, 1.5 - ~87% of gaussian energy is preserved and 2.0 is for 95%)
// For other values calculate "erfinv(0.01 * percents)*sqrt(2)" in MATLAB.
const CGFloat kGaussianEnergyFactor50Percent = 0.67449;
const CGFloat kGaussianEnergyFactor68Percent = 1.0;
const CGFloat kGaussianEnergyFactor87Percent = 1.5;
const CGFloat kGaussianEnergyFactor95Percent = 2.0;
const CGFloat kGaussianEnergyFactor99Percent = 3.0;

@implementation LTConsistentGaussianFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output sigma:(CGFloat)sigma
         gaussianEnergyFactor:(CGFloat)gaussianEnergyFactor {
  if (self = [super init]) {
    _spatialUnitProvider =
        [[LTConsistentGaussianFilterSpatialUnitProvider alloc] initWithInputSize:input.size];
    LTGaussianConvolutionDivider *divider = [self createDividerForImageSize:input.size sigma:sigma
                                                       gaussianEnergyFactor:gaussianEnergyFactor];
    [self createInternalProcessor:input output:output numberOfTaps:divider.numberOfFilterTaps
                            sigma:divider.iterationSigma
                       iterations:divider.iterationsRequired];
  }
  return self;
}

- (LTGaussianConvolutionDivider *)createDividerForImageSize:(CGSize)imageSize sigma:(CGFloat)sigma
                                       gaussianEnergyFactor:(CGFloat)gaussianEnergyFactor {
  NSUInteger maxNumberOfFilterTaps = [LTGaussianFilterProcessor maxNumberOfFilterTaps];
  CGFloat spatialUnit = [self.spatialUnitProvider spatialUnitForImageSize:imageSize];
  return [[LTGaussianConvolutionDivider alloc] initWithSigma:sigma
                                                 spatialUnit:spatialUnit
                                               maxFilterTaps:maxNumberOfFilterTaps
                                        gaussianEnergyFactor:gaussianEnergyFactor];
}

- (void)createInternalProcessor:(LTTexture *)input output:(LTTexture *)output
                   numberOfTaps:(NSUInteger)numOfTaps sigma:(CGFloat)sigma
                     iterations:(NSUInteger)iterations {
  _internalProcessor = [[LTGaussianFilterProcessor alloc] initWithInput:input outputs:@[output]
                                                           numberOfTaps:numOfTaps
                                                    spatialUnitProvider:self.spatialUnitProvider];
  self.internalProcessor.iterationsPerOutput = @[@(iterations)];
  self.internalProcessor.sigma = sigma;
}

- (void)process {
  [self.internalProcessor process];
}

@end

NS_ASSUME_NONNULL_END
