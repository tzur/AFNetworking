// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDuoProcessor.h"

#import "LTProgram.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTDuoFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTDuoProcessor ()

/// \c YES if dual mask needs processing prior to executing this processor.
@property (nonatomic) BOOL needsDualMaskProcessing;

/// Internal dual mask processor.
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

@end

@implementation LTDuoProcessor

static const CGFloat kMaskDownscalingFactor = 2;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup dual mask.
  CGSize maskSize = std::ceil(output.size / kMaskDownscalingFactor);
  LTTexture *dualMaskTexture = [LTTexture byteRedTextureWithSize:maskSize];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
  
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTDuoFsh source] sourceTexture:input
                       auxiliaryTextures:@{[LTDuoFsh dualMaskTexture]: dualMaskTexture}
                               andOutput:output]) {
    [self resetInputModel];
    [self setNeedsDualMaskUpdate];
  }
  return self;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTDuoProcessor, maskType),
      @instanceKeypath(LTDuoProcessor, center),
      @instanceKeypath(LTDuoProcessor, diameter),
      @instanceKeypath(LTDuoProcessor, spread),
      @instanceKeypath(LTDuoProcessor, angle),
      @instanceKeypath(LTDuoProcessor, blueColor),
      @instanceKeypath(LTDuoProcessor, redColor),
      @instanceKeypath(LTDuoProcessor, blendMode),
      @instanceKeypath(LTDuoProcessor, opacity)
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
  return LTVector2Zero;
}

- (CGFloat)defaultDiameter {
  return 0;
}

- (CGFloat)defaultAngle {
  return 0;
}

- (LTDuoBlendMode)defaultBlendMode {
  return LTDuoBlendModeNormal;
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
  self.dualMaskProcessor.center = center / kMaskDownscalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (LTVector2)center {
  return self.dualMaskProcessor.center * kMaskDownscalingFactor;
}

- (void)setDiameter:(CGFloat)diameter {
  self.dualMaskProcessor.diameter = diameter / kMaskDownscalingFactor;
  [self setNeedsDualMaskUpdate];
}

- (CGFloat)diameter {
  return self.dualMaskProcessor.diameter * kMaskDownscalingFactor;
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self.dualMaskProcessor.spread = spread;
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
#pragma mark Colors
#pragma mark -

- (LTVector4)blackWithAlpha:(CGFloat)alpha {
  return LTVector4(0.0, 0.0, 0.0, alpha);
}

- (LTVector4)whiteWithAlpha:(CGFloat)alpha {
  return LTVector4(1.0, 1.0, 1.0, alpha);
}

LTPropertyWithoutSetter(LTVector4, blueColor, BlueColor,
                        LTVector4Zero, LTVector4One, LTVector4(0, 0, 1, 1));
- (void)setBlueColor:(LTVector4)blueColor {
  [self _verifyAndSetBlueColor:blueColor];
  self[[LTDuoFsh blueColor]] = $(blueColor);
}

LTPropertyWithoutSetter(LTVector4, redColor, RedColor,
                        LTVector4Zero, LTVector4One, LTVector4(1, 0, 0, 1));
- (void)setRedColor:(LTVector4)redColor {
  [self _verifyAndSetRedColor:redColor];
  self[[LTDuoFsh redColor]] = $(redColor);
}

- (void)setBlendMode:(LTDuoBlendMode)blendMode {
  _blendMode = blendMode;
  self[[LTDuoFsh blendMode]] = @(blendMode);
}

LTPropertyWithoutSetter(CGFloat, opacity, Opacity, 0, 1, 0);
- (void)setOpacity:(CGFloat)opacity {
  [self _verifyAndSetOpacity:opacity];
  self[[LTDuoFsh opacity]] = @(opacity);
}

@end
