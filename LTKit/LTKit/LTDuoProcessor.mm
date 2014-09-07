// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDuoProcessor.h"

#import "LTProgram.h"
#import "LTDualMaskProcessor.h"
#import "LTCGExtensions.h"
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
    [self setDefaultValues];
    self.needsDualMaskProcessing = YES;
  }
  return self;
}

- (void)preprocess {
  [self processSubProcessors];
}

- (void)processSubProcessors {
  if (self.needsDualMaskProcessing) {
    [self.dualMaskProcessor process];
    self.needsDualMaskProcessing = NO;
  }
}

- (void)setDefaultValues {
  self.blueColor = self.defaultBlueColor;
  self.redColor = self.defaultRedColor;
  self.opacity = self.defaultOpacity;
  self.blendMode = LTDuoBlendModeNormal;
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  self.needsDualMaskProcessing = YES;
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(LTVector2)center {
  self.dualMaskProcessor.center = center / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
}

- (LTVector2)center {
  return self.dualMaskProcessor.center * kMaskDownscalingFactor;
}

- (void)setDiameter:(CGFloat)diameter {
  self.dualMaskProcessor.diameter = diameter / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
}

- (CGFloat)diameter {
  return self.dualMaskProcessor.diameter * kMaskDownscalingFactor;
}

- (void)setSpread:(CGFloat)spread {
  self.dualMaskProcessor.spread = spread;
  self.needsDualMaskProcessing = YES;
}

- (CGFloat)spread {
  return self.dualMaskProcessor.spread;
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  self.needsDualMaskProcessing = YES;
}

- (CGFloat)angle {
  return self.dualMaskProcessor.angle;
}

#pragma mark -
#pragma mark Colors
#pragma mark -

static const ushort kGradientSize = 256;

- (LTVector4)blackWithAlpha:(CGFloat)alpha {
  return LTVector4(0.0, 0.0, 0.0, alpha);
}

- (LTVector4)whiteWithAlpha:(CGFloat)alpha {
  return LTVector4(1.0, 1.0, 1.0, alpha);
}

// TODO:(zeev) Decide between the options here. One option is creating a gradient given a color
// that maps color to midrange, black to black and white to white. It creates better results using
// normal blending mode, but is more confusing when we introduce over blending modes.
// Thus for now we try another option and create a constant gradient. If it sticks, we can change
// the shader to receive a single color instead of the gradient.
- (LTColorGradient *)createGradientWithColor:(LTVector4)color {
  NSArray *controlPoints =
      @[[[LTColorGradientControlPoint alloc] initWithPosition:0.0 colorWithAlpha:color],
        [[LTColorGradientControlPoint alloc] initWithPosition:1.0 colorWithAlpha:color]];
  return [[LTColorGradient alloc] initWithControlPoints:controlPoints];
}

- (void)updateGradientWithColor:(LTVector4)color uniformName:(NSString *)uniformName {
  // Create a new gradient.
  LTColorGradient *gradient = [self createGradientWithColor:color];
  
  // Update gradient texture in auxiliary textures.
  [self setAuxiliaryTexture:[gradient textureWithSamplingPoints:kGradientSize]
                   withName:uniformName];
}

LTPropertyWithoutSetter(LTVector4, blueColor, BlueColor,
                        LTVector4Zero, LTVector4One, LTVector4(0, 0, 1, 1));
- (void)setBlueColor:(LTVector4)blueColor {
  [self _verifyAndSetBlueColor:blueColor];
  [self updateGradientWithColor:blueColor uniformName:[LTDuoFsh blueLUT]];
}

LTPropertyWithoutSetter(LTVector4, redColor, RedColor,
                        LTVector4Zero, LTVector4One, LTVector4(1, 0, 0, 1));
- (void)setRedColor:(LTVector4)redColor {
  [self _verifyAndSetRedColor:redColor];
  [self updateGradientWithColor:redColor uniformName:[LTDuoFsh redLUT]];
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
