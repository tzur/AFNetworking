// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValue+LTVector.h"

@implementation NSValue (LTVector)

- (LTVector2)LTVector2Value {
  LTVector2 vector;
  [self getValue:&vector];
  return vector;
}

- (LTVector3)LTVector3Value {
  LTVector3 vector;
  [self getValue:&vector];
  return vector;
}

- (LTVector4)LTVector4Value {
  LTVector4 vector;
  [self getValue:&vector];
  return vector;
}

+ (NSValue *)valueWithLTVector2:(LTVector2)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(LTVector2)];
}

+ (NSValue *)valueWithLTVector3:(LTVector3)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(LTVector3)];
}

+ (NSValue *)valueWithLTVector4:(LTVector4)vector {
  return [NSValue valueWithBytes:&vector objCType:@encode(LTVector4)];
}


@end
