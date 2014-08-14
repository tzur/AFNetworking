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

- (void)process {
  [self processSubProcessors];
  return [super process];
}

- (void)processToFramebufferWithSize:(CGSize)size outputRect:(CGRect)rect {
  [self processSubProcessors];
  [super processToFramebufferWithSize:size outputRect:rect];
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

- (void)setCenter:(GLKVector2)center {
  self.dualMaskProcessor.center = center / kMaskDownscalingFactor;
  self.needsDualMaskProcessing = YES;
}

- (GLKVector2)center {
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

- (GLKVector4)blackWithAlpha:(CGFloat)alpha {
  return GLKVector4Make(0.0, 0.0, 0.0, alpha);
}

- (GLKVector4)whiteWithAlpha:(CGFloat)alpha {
  return GLKVector4Make(1.0, 1.0, 1.0, alpha);
}

// Given color creates a gradient that maps color to midrange. Black is mapped to black and white
// to white. Alpha of the gradient is constant and equals to the alpha of the color.
- (LTColorGradient *)createGradientWithColor:(GLKVector4)color {
  LTColorGradientControlPoint *blackControlPoint = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.0 colorWithAlpha:[self blackWithAlpha:color.a]];
  LTColorGradientControlPoint *midControlPoint = [[LTColorGradientControlPoint alloc]
      initWithPosition:0.5 colorWithAlpha:color];
  LTColorGradientControlPoint *whiteControlPoint = [[LTColorGradientControlPoint alloc]
      initWithPosition:1.0 colorWithAlpha:[self whiteWithAlpha:color.a]];
  
  NSArray *controlPoints = @[blackControlPoint, midControlPoint, whiteControlPoint];
  return [[LTColorGradient alloc] initWithControlPoints:controlPoints];
}

- (void)updateGradientWithColor:(GLKVector4)color uniformName:(NSString *)uniformName {
  // Create a new gradient.
  LTColorGradient *gradient = [self createGradientWithColor:color];
  
  // Update gradient texture in auxiliary textures.
  [self setAuxiliaryTexture:[gradient textureWithSamplingPoints:kGradientSize]
                   withName:uniformName];
}

LTPropertyWithoutSetter(GLKVector4, blueColor, BlueColor,
                        GLKVector4Zero, GLKVector4One, GLKVector4Make(0, 0, 1, 1));
- (void)setBlueColor:(GLKVector4)blueColor {
  [self _verifyAndSetBlueColor:blueColor];
  [self updateGradientWithColor:blueColor uniformName:[LTDuoFsh blueLUT]];
}

LTPropertyWithoutSetter(GLKVector4, redColor, RedColor,
                        GLKVector4Zero, GLKVector4One, GLKVector4Make(1, 0, 0, 1));
- (void)setRedColor:(GLKVector4)redColor {
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
