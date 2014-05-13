// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerParams.h"

#import "LTGLKitExtensions.h"
#import "LTPropertyMacros.h"

@implementation LTShapeDrawerParams

- (instancetype)init {
  if (self = [super init]) {
    [self setDefaults];
  }
  return self;
}

- (void)setDefaults {
  self.lineWidth = self.defaultLineWidth;
  self.shadowWidth = self.defaultShadowWidth;
  self.fillColor = self.defaultFillColor;
  self.strokeColor = self.defaultStrokeColor;
  self.shadowColor = self.defaultShadowColor;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  
  LTShapeDrawerParams *other = object;
  return self.lineWidth == other.lineWidth &&
         self.shadowWidth == other.shadowWidth &&
         self.fillColor == other.fillColor &&
         self.strokeColor == other.strokeColor &&
         self.shadowColor == other.shadowColor;
}

- (id)copyWithZone:(NSZone *)zone {
  LTShapeDrawerParams *params = [[[self class] allocWithZone:zone] init];
  params.lineWidth = self.lineWidth;
  params.shadowWidth = self.shadowWidth;
  params.fillColor = self.fillColor;
  params.strokeColor = self.strokeColor;
  params.shadowColor = self.shadowColor;
  return params;
}


- (CGFloat)lineRadius {
  return 0.5 * self.lineWidth;
}

LTBoundedPrimitivePropertyImplement(CGFloat, lineWidth, LineWidth, 1, CGFLOAT_MAX, 1);
LTBoundedPrimitivePropertyImplement(CGFloat, shadowWidth, ShadowWidth, 0, CGFLOAT_MAX, 0);
LTBoundedPrimitivePropertyImplement(GLKVector4, fillColor, FillColor,
                                    GLKVector4Zero, GLKVector4One, GLKVector4One);
LTBoundedPrimitivePropertyImplement(GLKVector4, strokeColor, StrokeColor,
                                    GLKVector4Zero, GLKVector4One, GLKVector4One);
LTBoundedPrimitivePropertyImplement(GLKVector4, shadowColor, ShadowColor,
                                    GLKVector4Zero, GLKVector4One, GLKVector4Make(0, 0, 0, 1));

@end
