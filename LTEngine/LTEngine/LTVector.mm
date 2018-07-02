// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

#import "NSScanner+LTEngine.h"

#pragma mark -
#pragma mark LTVector2
#pragma mark -

NSString *NSStringFromLTVector2(LTVector2 vector) {
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

NSString *NSStringFromLTVector3(LTVector3 vector) {
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
  float v = std::max(*this);
  float minRGB = std::min(*this);
  float diffVminRGB = v - minRGB;
  float denominator = diffVminRGB * 6;
  float h;
  if (v == x) {
    h = denominator ? (y - z) / denominator : 0;
  } else if (v == y) {
    h = 1.0f / 3 + (z - x) / denominator;
  } else {
    h = 2.0f / 3 + (x - y) / denominator;
  }

  if (h < 0) {
    h += 1;
  }

  return LTVector3(h, v ? diffVminRGB / v : 0, v);
}

LTVector3 LTVector3::hsvToRgb() const {
  cv::Mat3f hsvMat(1, 1, cv::Vec3f(x * 360, y, z));
  cv::Mat3f rgbMat(1, 1);
  cv::cvtColor(hsvMat, rgbMat, cv::COLOR_HSV2RGB);
  return LTVector3(rgbMat(0, 0)[0], rgbMat(0, 0)[1], rgbMat(0, 0)[2]);
}

#pragma mark -
#pragma mark LTVector4
#pragma mark -

NSString *NSStringFromLTVector4(LTVector4 vector) {
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
