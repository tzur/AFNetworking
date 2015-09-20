// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "UIColor+Vector.h"

#import "LTGLKitExtensions.h"

@implementation UIColor (Vector)

+ (UIColor *)lt_colorWithLTVector:(LTVector4)vector {
  return [UIColor colorWithRed:vector.r() green:vector.g() blue:vector.b() alpha:vector.a()];
}

- (LTVector4)lt_ltVector {
  CGFloat r, g, b, a;
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return LTVector4(r, g, b, a);
  } else if ([self getWhite:&r alpha:&a]) {
    return LTVector4(r, r, r, a);
  }
  LTAssert(NO, @"Invalid color for conversion: %@", self);
}

- (LTVector4)lt_ltVectorHSVA {
  CGFloat h, s, b, a;
  if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
    return LTVector4(h, s, b, a);
  } else if ([self getWhite:&b alpha:&a]) {
    return LTVector4(0, 0, b, a);
  }
  LTAssert(NO, @"Invalid color for conversion: %@", self);
}

- (cv::Vec4b)lt_cvVector {
  CGFloat r, g, b, a;
  static const uchar kMax = std::numeric_limits<uchar>::max();
  if ([self getRed:&r green:&g blue:&b alpha:&a]) {
    return cv::Vec4b(std::round(r * kMax), std::round(g * kMax),
                     std::round(b * kMax), std::round(a * kMax));
  } else if ([self getWhite:&r alpha:&a]) {
    return cv::Vec4b(std::round(r * kMax), std::round(r * kMax),
                     std::round(r * kMax), std::round(a * kMax));
  }
  LTAssert(NO, @"Invalid color for conversion: %@", self);
}

@end
