// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTTiltShiftProcessor.h"

#import "LTBicubicResizeProcessor.h"
#import "LTDualMaskProcessor.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTGLKitExtensions.h"
#import "LTMaskedBlurProcessor.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTTiltShiftFsh.h"
#import "LTSmoothPyramidProcessor.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTTiltShiftProcessor ()

/// \c YES if dual mask needs processing prior to executing this processor.
@property (nonatomic) BOOL needsDualMaskProcessing;

/// Internal dual mask processor.
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

/// Internal processor that applies blur on input according to result of \c dualMaskProcessor.
@property (strong, nonatomic) LTMaskedBlurProcessor *maskedBlurProcessor;

@end

@implementation LTTiltShiftProcessor

// Since dual mask is smooth, strong downsampling will have very little impact on the quality, while
// significantly reducing the memory requirements.
static const CGFloat kMaskScalingFactor = 4.0;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *mask = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
  [mask clearWithColor:LTVector4(1)];
  return [self initWithInput:input mask:mask output:output];
}

- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output {
  // Setup dual mask.
  LTTexture *dualMaskTexture = [self createDualMaskTextureWithOutput:output];

  if (self = [super init]) {
    self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
    self.maskedBlurProcessor = [[LTMaskedBlurProcessor alloc] initWithInput:input mask:mask
                                                                   blurMask:dualMaskTexture
                                                                     output:output];
    [self resetInputModel];
  }
  return self;
}

- (LTTexture *)createDualMaskTextureWithOutput:(LTTexture *)output {
  CGSize maskSize = CGSizeMake(MAX(1, std::round(output.size.width / kMaskScalingFactor)),
                               MAX(1, std::round(output.size.height / kMaskScalingFactor)));
  return [LTTexture byteRedTextureWithSize:maskSize];
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTTiltShiftProcessor, maskType),
      @instanceKeypath(LTTiltShiftProcessor, center),
      @instanceKeypath(LTTiltShiftProcessor, diameter),
      @instanceKeypath(LTTiltShiftProcessor, spread),
      @instanceKeypath(LTTiltShiftProcessor, stretch),
      @instanceKeypath(LTTiltShiftProcessor, angle),
      @instanceKeypath(LTTiltShiftProcessor, invertMask),
      @instanceKeypath(LTTiltShiftProcessor, intensity)
    ]];
  });
  
  return properties;
}

+ (BOOL)isPassthroughForDefaultInputModel {
  return NO;
}

- (LTDualMaskType)defaultMaskType {
  return LTDualMaskTypeRadial;
}

- (LTVector2)defaultCenter {
  return LTVector2::zeros();
}

- (CGFloat)defaultDiameter {
  return 0;
}

- (CGFloat)defaultAngle {
  return 0;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [super preprocess];

  if (self.needsDualMaskProcessing) {
    [self.dualMaskProcessor process];
    self.needsDualMaskProcessing = NO;
  }
}

- (void)process {
  [self preprocess];

  [self.maskedBlurProcessor process];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self preprocess];

  [self.maskedBlurProcessor processToFramebufferWithSize:size outputRect:rect];
}

- (void)processInRect:(CGRect)rect {
  [self preprocess];

  [self.maskedBlurProcessor processInRect:rect];
}


- (void)setNeedsDualMaskUpdate {
  self.needsDualMaskProcessing = YES;
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  [self setNeedsDualMaskUpdate];
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.center = center / kMaskScalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (LTVector2)center {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.center * kMaskScalingFactor;
}

- (void)setDiameter:(CGFloat)diameter {
  // Scaling transforms from image coordinate system to mask coordinate system.
  self.dualMaskProcessor.diameter = diameter / kMaskScalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (CGFloat)diameter {
  // Scaling transforms from mask coordinate system to image coordinate system.
  return self.dualMaskProcessor.diameter * kMaskScalingFactor;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self.dualMaskProcessor.spread = spread;
  [self setNeedsDualMaskUpdate];
}

LTPropertyProxyWithoutSetter(CGFloat, stretch, Stretch, self.dualMaskProcessor);
- (void)setStretch:(CGFloat)stretch {
  self.dualMaskProcessor.stretch = stretch;
  [self setNeedsDualMaskUpdate];
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  [self setNeedsDualMaskUpdate];
}

- (CGFloat)angle {
  return self.dualMaskProcessor.angle;
}

#pragma mark -
#pragma mark Blur
#pragma mark -

LTPropertyProxy(CGFloat, intensity, Intensity, self.maskedBlurProcessor);

- (void)setInvertMask:(BOOL)invertMask {
  _invertMask = invertMask;
  self.dualMaskProcessor.invert = invertMask;
  [self setNeedsDualMaskUpdate];
}

#pragma mark -
#pragma mark Input/Output
#pragma mark -

- (CGSize)inputSize {
  return self.maskedBlurProcessor.inputSize;
}

- (CGSize)outputSize {
  return self.maskedBlurProcessor.outputSize;
}

- (LTTexture *)outputTexture {
  return self.maskedBlurProcessor.outputTexture;
}

- (LTTexture *)inputTexture {
  return self.maskedBlurProcessor.inputTexture;
}

@end
