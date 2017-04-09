// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTDualMaskFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTDualMaskProcessor

- (instancetype)initWithOutput:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTDualMaskFsh source] sourceTexture:output
                       auxiliaryTextures:nil
                               andOutput:output]) {
    [self setAspectRatioCorrectionWithSize:output.size];
    [self resetInputModel];
  }
  return self;
}

- (void)setDefaultValues {
  self.maskType = LTDualMaskTypeRadial;
  self.center = LTVector2(self.outputSize.width / 2, self.outputSize.height / 2);
  self.spread = self.defaultSpread;
  self.diameter = MIN(self.outputSize.width, self.outputSize.height) / 2;
  self.angle = 0.0;
}

- (void)setAspectRatioCorrectionWithSize:(CGSize)size {
  LTVector2 aspectRatioCorrection;
  if (size.width > size.height) {
    aspectRatioCorrection = LTVector2(size.width/size.height, 1);
  } else {
    aspectRatioCorrection = LTVector2(1, size.height/size.width);
  }
  self[[LTDualMaskFsh aspectRatioCorrection]] = $(aspectRatioCorrection);
}

#pragma mark -
#pragma mark Input model
#pragma mark -

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTDualMaskProcessor, maskType),
      @instanceKeypath(LTDualMaskProcessor, center),
      @instanceKeypath(LTDualMaskProcessor, diameter),
      @instanceKeypath(LTDualMaskProcessor, spread),
      @instanceKeypath(LTDualMaskProcessor, stretch),
      @instanceKeypath(LTDualMaskProcessor, angle),
      @instanceKeypath(LTDualMaskProcessor, invert)
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

- (CGFloat)defaultStretch {
  return 1;
}

- (CGFloat)defaultAngle {
  return 0;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  _maskType = maskType;
  self[[LTDualMaskFsh maskType]] = @(maskType);
  [self updateDiameterWith:self.diameter];
}

- (void)setCenter:(LTVector2)center {
  _center = center;
  if (!center.isNull()) {
    LTVector2 remap = LTVector2(center.x / self.outputSize.width,
                                center.y / self.outputSize.height);
    self[[LTDualMaskFsh center]] = $(remap);
  }
}

- (void)updateDiameterWith:(CGFloat)diameter {
  if (self.maskType == LTDualMaskTypeRadial || self.maskType == LTDualMaskTypeDoubleLinear) {
    CGFloat remap = diameter / MIN(self.outputSize.width, self.outputSize.height) - 0.5;
    self[[LTDualMaskFsh shift]] = @(remap);
  } else if (self.maskType == LTDualMaskTypeLinear) {
    self[[LTDualMaskFsh shift]] = @(-0.5);
  }
}

- (void)setDiameter:(CGFloat)diameter {
  _diameter = diameter;
  [self updateDiameterWith:diameter];
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, -1, 1, 0);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self[[LTDualMaskFsh spread]] = @([self remapSpread:spread]);
}

- (void)setStretch:(CGFloat)stretch {
  LTParameterAssert(stretch > 0, @"Stretch (%g) must be positive", stretch);
  _stretch = stretch;
  self[[LTDualMaskFsh stretchInversed]] = @(1 / stretch);
}

- (CGFloat)remapSpread:(CGFloat)spread {
  static const CGFloat kSpreadPositiveScaling = 1.5;
  static const CGFloat kSpreadNegativeScaling = 0.49;
  if (spread > 0) {
    return spread * kSpreadPositiveScaling;
  } else {
    return spread * kSpreadNegativeScaling;
  }
}

- (void)setAngle:(CGFloat)angle {
  _angle = angle;
  self[[LTDualMaskFsh rotation]] = $(GLKMatrix2MakeRotation(-angle));
  self[[LTDualMaskFsh normal]] = $(LTVector2(cos(angle), -sin(angle)));
}

- (void)setInvert:(BOOL)invert {
  _invert = invert;
  self[[LTDualMaskFsh invert]] = @(invert);
}

@end
