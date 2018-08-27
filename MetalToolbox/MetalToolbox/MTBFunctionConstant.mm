// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBFunctionConstant.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcomma"
#import <half.hpp>
#pragma clang diagnostic pop

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

+ (instancetype)boolConstantWithValue:(BOOL)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(BOOL)]
                                type:MTLDataTypeBool name:name];
}

+ (instancetype)shortConstantWithValue:(short)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(short)]
                                type:MTLDataTypeShort name:name];
}

+ (instancetype)short2ConstantWithValue:(simd_short2)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_short2)]
                                type:MTLDataTypeShort2 name:name];
}

+ (instancetype)short4ConstantWithValue:(simd_short4)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_short4)]
                                type:MTLDataTypeShort4 name:name];
}

+ (instancetype)ushortConstantWithValue:(ushort)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(ushort)]
                                type:MTLDataTypeUShort name:name];
}

+ (instancetype)ushort2ConstantWithValue:(simd_ushort2)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_ushort2)]
                                type:MTLDataTypeUShort2 name:name];
}

+ (instancetype)ushort4ConstantWithValue:(simd_ushort4)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_ushort4)]
                                type:MTLDataTypeUShort4 name:name];
}

+ (instancetype)uintConstantWithValue:(uint)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(uint)]
                                type:MTLDataTypeUInt name:name];
}

+ (instancetype)uint2ConstantWithValue:(simd_uint2)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_uint2)]
                                type:MTLDataTypeUInt2 name:name];
}

+ (instancetype)uint4ConstantWithValue:(simd_uint4)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(simd_uint4)]
                                type:MTLDataTypeUInt4 name:name];
}

+ (instancetype)floatConstantWithValue:(float)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(float)]
                                type:MTLDataTypeFloat name:name];
}

+ (instancetype)halfConstantWithValue:(half_float::half)value name:(NSString *)name {
  return [[self alloc] initWithValue:[NSData dataWithBytes:&value length:sizeof(half_float::half)]
                                type:MTLDataTypeHalf name:name];
}

@end

NS_ASSUME_NONNULL_END
