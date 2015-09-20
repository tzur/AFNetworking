// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTVector.h"

@interface NSValue (LTVector)

- (LTVector2)LTVector2Value;
- (LTVector3)LTVector3Value;
- (LTVector4)LTVector4Value;

+ (NSValue *)valueWithLTVector2:(LTVector2)vector;
+ (NSValue *)valueWithLTVector3:(LTVector3)vector;
+ (NSValue *)valueWithLTVector4:(LTVector4)vector;

@end
