// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTDualMaskFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTDualMaskProcessor

- (instancetype)initWithOutput:(LTTexture *)output {
  if (self = [super initWithProgram:[self createProgram] sourceTexture:output auxiliaryTextures:nil
                          andOutput:output]) {
    [self setDefaultValues];
  }
  return self;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTDualMaskFsh source]];
}

- (void)setDefaultValues {
  self.maskType = LTDualMaskTypeRadial;
  self.center = self.defaultCenter;
  self.spread = self.defaultSpread;
  self.diameter = self.defaultDiameter;
  self.angle = self.defaultAngle;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setMaskType:(LTDualMaskType)maskType {
  _maskType = maskType;
  self[@"maskType"] = @(maskType);
  [self updateDiameterWith:self.diameter];
}

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector2, center, Center,
                                                 GLKVector2Make(0, 0),
                                                 GLKVector2Make(1, 1),
                                                 GLKVector2Make(0.5, 0.5));

- (void)setCenter:(GLKVector2)center {
  LTParameterAssert(GLKVector2AllGreaterThanOrEqualToVector2(center, self.minCenter));
  LTParameterAssert(GLKVector2AllGreaterThanOrEqualToVector2(self.maxCenter, center));
  _center = center;
  self[@"center"] = $(center);
}

- (void)updateDiameterWith:(CGFloat)diameter {
  if (self.maskType == LTDualMaskTypeRadial || self.maskType == LTDualMaskTypeDoubleLinear) {
    self[@"shift"] = @(diameter - 0.5);
  } else if (self.maskType == LTDualMaskTypeLinear) {
    self[@"shift"] = @(-0.5);
  }
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, diameter, Diameter, 0, 1, 0.5, ^{
  [self updateDiameterWith:diameter];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, spread, Spread, -1, 1, 0, ^{
  static const CGFloat kSpreadScaling = 0.45;
  CGFloat remap = spread * kSpreadScaling;
  self[@"spread"] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, angle, Angle, -M_PI, M_PI, 0, ^{
  self[@"normal"] = $(GLKVector2Make(cos(angle), sin(angle)));
});

@end
