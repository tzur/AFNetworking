// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGaussianFilterProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTGaussianFilterProcessorFsh.h"
#import "LTShaderStorage+LTGaussianFilterProcessorVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTDefaultGaussianSpatialUnitProvider
#pragma mark -

/// Scales the spatial unit so the blur radius will be consistant with input image size.
@interface LTDefaultGaussianSpatialUnitProvider : NSObject <LTGaussianFilterSpatialUnitProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the spatial unit provider with the size of input image.
- (instancetype)initWithInputSize:(CGSize)inputSize NS_DESIGNATED_INITIALIZER;

/// Input image size.
@property (readonly, nonatomic) CGSize inputSize;

@end

@implementation LTDefaultGaussianSpatialUnitProvider

- (instancetype)initWithInputSize:(CGSize)inputSize {
  if (self = [super init]) {
    _inputSize = inputSize;
  }
  return self;
}

- (CGFloat)spatialUnitForImageSize:(CGSize)size {
  return self.inputSize.width / size.width;
}

@end

#pragma mark -
#pragma mark LTGaussianFilterProcessor
#pragma mark -

@interface LTGaussianFilterProcessor ()

/// Input texture size.
@property (readonly, nonatomic) CGSize inputSize;

/// First output texture size.
@property (readonly, nonatomic) CGSize firstOutputSize;

/// Spatial unit provider.
@property (readonly, nonatomic) id<LTGaussianFilterSpatialUnitProvider> spatialUnitProvider;

@end

@implementation LTGaussianFilterProcessor

static NSString * const kNumberOfTapsPlaceholder = @"@NUMBER_OF_TAPS@";

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTGaussianFilterProcessor, sigma)
    ]];
  });
  return properties;
}

+ (NSUInteger)maxNumberOfFilterTaps {
  // NOTE: This value is not arbitrary, increasing it may impose unexpected x10 increase
  // of the running time. Needs to be checked on the real HW if increased.
  //
  // It was tested on iPhone 5S, iPhone 6, iPad Pro, iPhone SE. In reality the preferred value for
  // iPhone 5S was 17. For iPhone 6, iPad Pro, iPhone SE it was 15. Since there's some kind of
  // a regression here it was decided to be on a safe side and to reduce it further to 13.
  return 13;
}

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
                 numberOfTaps:(NSUInteger)numberOfTaps
          spatialUnitProvider:(id<LTGaussianFilterSpatialUnitProvider>)spatialUnitProvider {
  [LTGaussianFilterProcessor validateInput:input outputs:outputs numberOfTaps:numberOfTaps];
  LTParameterAssert(spatialUnitProvider);

  NSString *numberOfTapsString = [NSString stringWithFormat:@"%lu", (unsigned long)numberOfTaps];
  NSString *vshSource = [[LTGaussianFilterProcessorVsh source]
      stringByReplacingOccurrencesOfString:kNumberOfTapsPlaceholder withString:numberOfTapsString];
  NSString *fshSource = [[LTGaussianFilterProcessorFsh source]
      stringByReplacingOccurrencesOfString:kNumberOfTapsPlaceholder withString:numberOfTapsString];
  if (self = [super initWithVertexSource:vshSource fragmentSource:fshSource
                           sourceTexture:input outputs:outputs]) {
    _inputSize = input.size;
    _firstOutputSize = [outputs.firstObject size];
    _spatialUnitProvider = spatialUnitProvider;
    [self resetInputModel];
  }
  return self;
}

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
                 numberOfTaps:(NSUInteger)numberOfTaps {
  id<LTGaussianFilterSpatialUnitProvider> defaultSpatialUnitProvider =
      [[LTDefaultGaussianSpatialUnitProvider alloc] initWithInputSize:input.size];
  return [self initWithInput:input outputs:outputs numberOfTaps:numberOfTaps
         spatialUnitProvider:defaultSpatialUnitProvider];
}

+ (void)validateInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs
         numberOfTaps:(NSUInteger)numberOfTaps {
  LTParameterAssert(input);
  LTParameterAssert(outputs.count);
  int firstOutputWidth = [outputs.firstObject size].width;
  int firstOutputHeight = [outputs.firstObject size].height;
  for (LTTexture *output in outputs) {
    int outputWidth = output.size.width;
    int outputHeight = output.size.height;
    LTParameterAssert(firstOutputWidth == outputWidth,
                      @"Output textures width differ(first: %d vs: %d)", firstOutputWidth,
                      outputWidth);
    LTParameterAssert(firstOutputHeight == outputHeight,
                      @"Output textures height differ(first: %d vs: %d)", firstOutputHeight,
                      outputHeight);
  }

  LTParameterAssert(numberOfTaps <= [LTGaussianFilterProcessor maxNumberOfFilterTaps],
      @"numberOfTaps (%lu) should not exceed maximum (%lu)", (unsigned long)numberOfTaps,
      (unsigned long)[[self class] maxNumberOfFilterTaps]);
  LTParameterAssert(numberOfTaps % 2, @"numberOfTaps (%lu) should be odd",
      (unsigned long)numberOfTaps);
}

- (void)iterationStarted:(NSUInteger)iteration {
  [super iterationStarted:iteration];
  CGSize size = (iteration == 0) ? self.inputSize : self.firstOutputSize;
  self[[LTGaussianFilterProcessorFsh spatialUnit]] =
      @([self.spatialUnitProvider spatialUnitForImageSize:size]);
}

LTPropertyWithoutSetter(CGFloat, sigma, Sigma, 0, std::numeric_limits<CGFloat>::max(), 1);
- (void)setSigma:(CGFloat)sigma {
  [self _verifyAndSetSigma:sigma];
  self[[LTGaussianFilterProcessorFsh expDenominator]] = @(sigma * sigma * 2);
}

@end

NS_ASSUME_NONNULL_END
