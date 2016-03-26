// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

#pragma mark -
#pragma mark NSScanner (NonNumberFloats)
#pragma mark -

/// Category adding the ability to scan floats while correctly handling valid non-numeric values.
@interface NSScanner (NonNumberFloats)
@end

@implementation NSScanner (NonNumberFloats)

/// Scans for a float value, returning a found value by reference. This method correctly handles
/// non-numeric values such as NaN, Infinity and -Infinity.
- (BOOL)lt_scanFloat:(float *)result {
  if ([self scanString:@"nan" intoString:NULL]) {
    if (result) {
      *result = NAN;
    }
    return YES;
  } else if ([self scanString:@"inf" intoString:NULL]) {
    if (result) {
      *result = INFINITY;
    }
    return YES;
  } else if ([self scanString:@"-inf" intoString:NULL]) {
    if (result) {
      *result = -INFINITY;
    }
    return YES;
  }

  return [self scanFloat:result];
}

@end

#pragma mark -
#pragma mark LTVector2
#pragma mark -

NSString *NSStringFromLTVector2(const LTVector2 &vector) {
  return [NSString stringWithFormat:@"(%g, %g)", vector.x, vector.y];
}

LTVector2 LTVector2FromString(NSString *string) {
  NSScanner *scanner = [NSScanner scannerWithString:string];
  float x, y;
  if (![scanner scanString:@"(" intoString:nil]) return LTVector2();
  if (![scanner lt_scanFloat:&x]) return LTVector2();
  if (![scanner scanString:@"," intoString:nil]) return LTVector2();
  if (![scanner lt_scanFloat:&y]) return LTVector2();
  if (![scanner scanString:@")" intoString:nil]) return LTVector2();
  if (![scanner isAtEnd]) return LTVector2();
  return LTVector2(x, y);
}

#pragma mark -
#pragma mark LTVector3
#pragma mark -

NSString *NSStringFromLTVector3(const LTVector3 &vector) {
  return [NSString stringWithFormat:@"(%g, %g, %g)", vector.x, vector.y, vector.z];
}

LTVector3 LTVector3FromString(NSString *string) {
  NSScanner *scanner = [NSScanner scannerWithString:string];
  float x, y, z;
  if (![scanner scanString:@"(" intoString:nil]) return LTVector3();
  if (![scanner lt_scanFloat:&x]) return LTVector3();
  if (![scanner scanString:@"," intoString:nil]) return LTVector3();
  if (![scanner lt_scanFloat:&y]) return LTVector3();
  if (![scanner scanString:@"," intoString:nil]) return LTVector3();
  if (![scanner lt_scanFloat:&z]) return LTVector3();
  if (![scanner scanString:@")" intoString:nil]) return LTVector3();
  if (![scanner isAtEnd]) return LTVector3();
  return LTVector3(x, y, z);
}
 LTVector3 LTVector3::rgbToHsv() const {
  cv::Mat3f rgbMat(1, 1, cv::Vec3f(x, y, z));
  cv::Mat3f hsvMat(1, 1);
  cv::cvtColor(rgbMat, hsvMat, CV_RGB2HSV);
  return LTVector3(hsvMat(0, 0)[0] / 360, hsvMat(0, 0)[1], hsvMat(0, 0)[2]);
}

LTVector3 LTVector3::hsvToRgb() const {
  cv::Mat3f hsvMat(1, 1, cv::Vec3f(x * 360, y, z));
  cv::Mat3f rgbMat(1, 1);
  cv::cvtColor(hsvMat, rgbMat, CV_HSV2RGB);
  return LTVector3(rgbMat(0, 0)[0], rgbMat(0, 0)[1], rgbMat(0, 0)[2]);
}

#pragma mark -
#pragma mark LTVector4
#pragma mark -

NSString *NSStringFromLTVector4(const LTVector4 &vector) {
  return [NSString stringWithFormat:@"(%g, %g, %g, %g)", vector.x, vector.y, vector.z, vector.w];
}

LTVector4 LTVector4FromString(NSString *string) {
  NSScanner *scanner = [NSScanner scannerWithString:string];
  float x, y, z, w;
  if (![scanner scanString:@"(" intoString:nil]) return LTVector4();
  if (![scanner lt_scanFloat:&x]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner lt_scanFloat:&y]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner lt_scanFloat:&z]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner lt_scanFloat:&w]) return LTVector4();
  if (![scanner scanString:@")" intoString:nil]) return LTVector4();
  if (![scanner isAtEnd]) return LTVector4();
  return LTVector4(x, y, z, w);
}

LTVector4 LTVector4::rgbToHsv() const {
  return LTVector4(rgb().rgbToHsv(), w);
}

LTVector4 LTVector4::hsvToRgb() const {
  return LTVector4(rgb().hsvToRgb(), w);
}
