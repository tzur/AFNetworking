// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDuoProcessor.h"

#import "LTProgram.h"
#import "LTDualMaskProcessor.h"
#import "LTColorGradient.h"
#import "LTShaderStorage+LTDuoFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "LTGPUImageProcessor+Protected.h"

@interface LTDuoProcessor ()

@property (nonatomic) BOOL subProcessorInitialized;
@property (strong, nonatomic) LTDualMaskProcessor *dualMaskProcessor;

@end

@implementation LTDuoProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup dual mask.
  LTTexture *dualMaskTexture = [LTTexture textureWithPropertiesOf:output];
  self.dualMaskProcessor = [[LTDualMaskProcessor alloc] initWithOutput:dualMaskTexture];
  
  if (self = [super initWithProgram:[self createProgram] sourceTexture:input
                  auxiliaryTextures:@{[LTDuoFsh dualMaskTexture]: dualMaskTexture}
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTDuoFsh source]];
}

- (void)initializeSubProcessors {
  [self.dualMaskProcessor process];
  self.subProcessorInitialized = YES;
}

- (id<LTImageProcessorOutput>)process {
  if (!self.subProcessorInitialized) {
    [self initializeSubProcessors];
  }
  return [super process];
}

- (void)setDefaultValues {
  self.blueColor = self.defaultBlueColor;
  self.redColor = self.defaultRedColor;
  self.opacity = self.defaultOpacity;
}

#pragma mark -
#pragma mark Dual Mask
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  self.dualMaskProcessor.maskType = maskType;
  [self.dualMaskProcessor process];
}

- (LTDualMaskType)maskType {
  return self.dualMaskProcessor.maskType;
}

- (void)setCenter:(GLKVector2)center {
  self.dualMaskProcessor.center = center;
  [self.dualMaskProcessor process];
}

- (GLKVector2)center {
  return self.dualMaskProcessor.center;
}

- (void)setDiameter:(CGFloat)diameter {
  self.dualMaskProcessor.diameter = diameter;
  [self.dualMaskProcessor process];
}

- (CGFloat)diameter {
  return self.dualMaskProcessor.diameter;
}

- (void)setSpread:(CGFloat)spread {
  self.dualMaskProcessor.spread = spread;
  [self.dualMaskProcessor process];
}

- (CGFloat)spread {
  return self.dualMaskProcessor.spread;
}

- (void)setAngle:(CGFloat)angle {
  self.dualMaskProcessor.angle = angle;
  [self.dualMaskProcessor process];
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

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector4, blueColor, BlueColor,
                                                 GLKVector4Make(0, 0, 0, 0),
                                                 GLKVector4Make(1, 1, 1, 1),
                                                 GLKVector4Make(0, 0, 1, 1));

- (void)setBlueColor:(GLKVector4)blueColor {
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(blueColor, self.minBlueColor));
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(self.maxBlueColor, blueColor));
  _blueColor = blueColor;
  [self updateGradientWithColor:blueColor uniformName:[LTDuoFsh blueLUT]];
}

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector4, redColor, RedColor,
                                                 GLKVector4Make(0, 0, 0, 0),
                                                 GLKVector4Make(1, 1, 1, 1),
                                                 GLKVector4Make(1, 0, 0, 1));

- (void)setRedColor:(GLKVector4)redColor {
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(redColor, self.minRedColor));
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(self.maxRedColor, redColor));
  _redColor = redColor;
  [self updateGradientWithColor:redColor uniformName:[LTDuoFsh redLUT]];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, opacity, Opacity, 0, 1, 1, ^{
  self[[LTDuoFsh opacity]] = @(opacity);
});

@end
