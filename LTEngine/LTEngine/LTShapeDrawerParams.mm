// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTShapeDrawerParams.h"

#import "LTGLKitExtensions.h"

@implementation LTShapeDrawerParams

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

LTProperty(CGFloat, lineWidth, LineWidth, 1, CGFLOAT_MAX, 1);
LTProperty(CGFloat, shadowWidth, ShadowWidth, 0, CGFLOAT_MAX, 0);
LTProperty(LTVector4, fillColor, FillColor, LTVector4Zero, LTVector4One, LTVector4One);
LTProperty(LTVector4, strokeColor, StrokeColor, LTVector4Zero, LTVector4One, LTVector4One);
LTProperty(LTVector4, shadowColor, ShadowColor,
           LTVector4Zero, LTVector4One, LTVector4(0, 0, 0, 1));

@end
