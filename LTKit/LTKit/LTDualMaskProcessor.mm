// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTDualMaskProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTDualMaskFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTDualMaskProcessor ()
@property (nonatomic) CGSize maskSize;
@end

@implementation LTDualMaskProcessor

- (instancetype)initWithOutput:(LTTexture *)output {
  if (self = [super initWithProgram:[self createProgram] sourceTexture:output auxiliaryTextures:nil
                          andOutput:output]) {
    // TODO:(zeev) Remove it once Yaron adds public properties to access input/output size.
    self.maskSize = output.size;
    [self setAspectRatioCorrectionWithSize:output.size];
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
  self.center = GLKVector2Make(self.maskSize.width / 2, self.maskSize.height / 2);
  self.spread = self.defaultSpread;
  self.diameter = MIN(self.maskSize.width, self.maskSize.height) / 2;
  self.angle = self.defaultAngle;
}

- (void)setAspectRatioCorrectionWithSize:(CGSize)size {
  GLKVector2 aspectRatioCorrection;
  if (size.width > size.height) {
    aspectRatioCorrection = GLKVector2Make(size.width/size.height, 1);
  } else {
    aspectRatioCorrection = GLKVector2Make(1, size.height/size.width);
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

- (void)setCenter:(GLKVector2)center {
  _center = center;
  GLKVector2 remap = GLKVector2Make(center.x / self.maskSize.width,
                                    center.y / self.maskSize.height);
  self[[LTDualMaskFsh center]] = $(remap);
}

- (void)updateDiameterWith:(CGFloat)diameter {
  if (self.maskType == LTDualMaskTypeRadial || self.maskType == LTDualMaskTypeDoubleLinear) {
    CGFloat remap = diameter / MIN(self.maskSize.width, self.maskSize.height) - 0.5;
    self[[LTDualMaskFsh shift]] = @(remap);
  } else if (self.maskType == LTDualMaskTypeLinear) {
    self[[LTDualMaskFsh shift]] = @(-0.5);
  }
}

- (void)setDiameter:(CGFloat)diameter {
  _diameter = diameter;
  [self updateDiameterWith:diameter];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, spread, Spread, -1, 1, 0, ^{
  static const CGFloat kSpreadScaling = 0.45;
  CGFloat remap = spread * kSpreadScaling;
  self[[LTDualMaskFsh spread]] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, angle, Angle, -M_PI, M_PI, 0, ^{
  self[[LTDualMaskFsh normal]] = $(GLKVector2Make(cos(angle), sin(angle)));
});

@end
