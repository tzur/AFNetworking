// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "NSValue+MTLSize.h"

#import <Expecta/NSValue+Expecta.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSValue (MTLSize)

- (MTLSize)MTLSizeValue {
  MTLSize size;
  [self getValue:&size];
  return size;
}

+ (NSValue *)valueWithMTLSize:(MTLSize)size {
  NSValue *value = [NSValue valueWithBytes:&size objCType:@encode(MTLSize)];
  [value set_EXP_objCType:@encode(MTLSize)];
  return value;
}

@end

NS_ASSUME_NONNULL_END
