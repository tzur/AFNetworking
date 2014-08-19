// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "NSValue+LTRect.h"

@implementation NSValue (LTRect)

- (LTRect)LTRectValue {
  LTRect rect;
  [self getValue:&rect];
  return rect;
}

+ (NSValue *)valueWithLTRect:(LTRect)rect {
  return [NSValue valueWithBytes:&rect objCType:@encode(LTRect)];
}

@end
