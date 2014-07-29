// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

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
  if (![scanner scanFloat:&x]) return LTVector2();
  if (![scanner scanString:@"," intoString:nil]) return LTVector2();
  if (![scanner scanFloat:&y]) return LTVector2();
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
  if (![scanner scanFloat:&x]) return LTVector3();
  if (![scanner scanString:@"," intoString:nil]) return LTVector3();
  if (![scanner scanFloat:&y]) return LTVector3();
  if (![scanner scanString:@"," intoString:nil]) return LTVector3();
  if (![scanner scanFloat:&z]) return LTVector3();
  if (![scanner scanString:@")" intoString:nil]) return LTVector3();
  if (![scanner isAtEnd]) return LTVector3();
  return LTVector3(x, y, z);
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
  if (![scanner scanFloat:&x]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner scanFloat:&y]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner scanFloat:&z]) return LTVector4();
  if (![scanner scanString:@"," intoString:nil]) return LTVector4();
  if (![scanner scanFloat:&w]) return LTVector4();
  if (![scanner scanString:@")" intoString:nil]) return LTVector4();
  if (![scanner isAtEnd]) return LTVector4();
  return LTVector4(x, y, z, w);
}
