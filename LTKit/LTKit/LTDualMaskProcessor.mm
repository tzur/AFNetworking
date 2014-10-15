// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

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
    [self setDefaultValues];
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
#pragma mark Properties
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  _maskType = maskType;
  self[[LTDualMaskFsh maskType]] = @(maskType);
  [self updateDiameterWith:self.diameter];
}

- (void)setCenter:(LTVector2)center {
  _center = center;
  LTVector2 remap = LTVector2(center.x / self.outputSize.width, center.y / self.outputSize.height);
  self[[LTDualMaskFsh center]] = $(remap);
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
  self[[LTDualMaskFsh normal]] = $(LTVector2(cos(angle), -sin(angle)));
}

@end
