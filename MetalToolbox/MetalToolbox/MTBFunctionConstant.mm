// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBFunctionConstant.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MTBFunctionConstant

- (instancetype)initWithValue:(NSData *)value type:(MTLDataType)type name:(NSString *)name {
  if (self = [super init]) {
    _value = value;
    _type = type;
    _name = name;
  }
  return self;
}

+ (instancetype)constantWithValue:(NSData *)value type:(MTLDataType)type name:(NSString *)name {
  return [[self alloc] initWithValue:value type:type name:name];
}

@end

NS_ASSUME_NONNULL_END
