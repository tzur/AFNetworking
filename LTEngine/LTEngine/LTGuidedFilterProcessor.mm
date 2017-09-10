// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "LTGuidedFilterProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTGuidedFilterCoefficientsProcessor.h"
#import "LTOneShotImageProcessor.h"
#import "LTShaderStorage+LTGuidedFilterCombineFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTGuidedFilterProcessor ()

/// Internal processor to compute the guided filter coefficients.
@property (readonly, nonatomic) LTGuidedFilterCoefficientsProcessor *coefficientsProcessor;

/// Internal processor to combine the coefficients with the input.
@property (readonly, nonatomic) LTOneShotImageProcessor *combineProcessor;

@end

@implementation LTGuidedFilterProcessor

- (instancetype)initWithInput:(LTTexture *)input guide:(LTTexture *)guide
              downscaleFactor:(NSUInteger)downscaleFactor
                   kernelSize:(NSUInteger)kernelSize output:(LTTexture *)output {
  LTParameterAssert(input);
  LTParameterAssert(output);
  LTParameterAssert(downscaleFactor > 0, @"downscaleFactor(%lu) must be strictly positive",
                    (unsigned long)downscaleFactor);
  LTParameterAssert(input.components == output.components,
                    @"input(%lu) and output(%lu) should have the same amount of channels",
                    (unsigned long)input.pixelFormat.channels,
                    (unsigned long)output.pixelFormat.channels);
  LTParameterAssert((input.components == LTGLPixelComponentsR) ||
                    (input.components == LTGLPixelComponentsRGBA),
                    @"Provided input texture channels amount(%lu) is not supported",
                    (unsigned long)input.pixelFormat.channels);
  if (self = [super init]) {
    CGSize coefficientsSize = std::ceil(input.size / downscaleFactor);
    LTGLPixelFormat *coefficientsPixelFormat = input.pixelFormat;
    if (input != guide) {
      if (input.components == LTGLPixelComponentsR) {
        coefficientsPixelFormat = $(LTGLPixelFormatR16Float);
      } else {
        coefficientsPixelFormat = $(LTGLPixelFormatRGBA16Float);
      }
    }
    LTTexture *scaleCoefficients = [LTTexture textureWithSize:coefficientsSize
                                                  pixelFormat:coefficientsPixelFormat
                                               allocateMemory:YES];
    LTTexture *shiftCoefficients = [LTTexture textureWithPropertiesOf:scaleCoefficients];

    _coefficientsProcessor =
        [[LTGuidedFilterCoefficientsProcessor alloc] initWithInput:input
                                                             guide:guide
                                                 scaleCoefficients:@[scaleCoefficients]
                                                 shiftCoefficients:@[shiftCoefficients]
                                                       kernelSizes:{kernelSize}];

    NSDictionary<NSString *, LTTexture *> *auxiliaryTextures = @{
      [LTGuidedFilterCombineFsh scaleTexture]: scaleCoefficients,
      [LTGuidedFilterCombineFsh shiftTexture]: shiftCoefficients
    };
    _combineProcessor =
        [[LTOneShotImageProcessor alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                               fragmentSource:[LTGuidedFilterCombineFsh source]
                                                sourceTexture:guide
                                            auxiliaryTextures:auxiliaryTextures
                                                    andOutput:output];
    self.combineProcessor[[LTGuidedFilterCombineFsh useGuideLuminance]] =
        @((guide.components == LTGLPixelComponentsRGBA) &&
          (input.components == LTGLPixelComponentsR));

    [self resetInputModel];
  }
  return self;
}

- (void)process {
  [self.coefficientsProcessor process];
  [self.combineProcessor process];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTPropertyProxy(CGFloat, smoothingDegree, SmoothingDegree, self.coefficientsProcessor);

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTGuidedFilterProcessor, smoothingDegree)
    ]];
  });
  return properties;
}

@end

NS_ASSUME_NONNULL_END
