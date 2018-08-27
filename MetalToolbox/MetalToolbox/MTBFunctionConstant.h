// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

namespace half_float {
  class half;
};

/// Value class that contains data for creating a Metal function constant.
@interface MTBFunctionConstant : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a function constant with given \c value, \c type and \c name.
+ (instancetype)constantWithValue:(NSData *)value type:(MTLDataType)type name:(NSString *)name;

/// Creates a function constant with given bool \c value and \c name.
+ (instancetype)boolConstantWithValue:(BOOL)value name:(NSString *)name;

/// Creates a function constant with given short \c value and \c name.
+ (instancetype)shortConstantWithValue:(short)value name:(NSString *)name;

/// Creates a function constant with given short2 \c value and \c name.
+ (instancetype)short2ConstantWithValue:(simd_short2)value name:(NSString *)name;

/// Creates a function constant with given short4 \c value and \c name.
+ (instancetype)short4ConstantWithValue:(simd_short4)value name:(NSString *)name;

/// Creates a function constant with given ushort \c value and \c name.
+ (instancetype)ushortConstantWithValue:(ushort)value name:(NSString *)name;

/// Creates a function constant with given ushort2 \c value and \c name.
+ (instancetype)ushort2ConstantWithValue:(simd_ushort2)value name:(NSString *)name;

/// Creates a function constant with given ushort4 \c value and \c name.
+ (instancetype)ushort4ConstantWithValue:(simd_ushort4)value name:(NSString *)name;

/// Creates a function constant with given uint \c value and \c name.
+ (instancetype)uintConstantWithValue:(uint)value name:(NSString *)name;

/// Creates a function constant with given uint2 \c value and \c name.
+ (instancetype)uint2ConstantWithValue:(simd_uint2)values name:(NSString *)name;

/// Creates a function constant with given uint4 \c value and \c name.
+ (instancetype)uint4ConstantWithValue:(simd_uint4)values name:(NSString *)name;

/// Creates a function constant with given float \c value and \c name.
+ (instancetype)floatConstantWithValue:(float)value name:(NSString *)name;

/// Creates a function constant with given half float \c value and \c name.
+ (instancetype)halfConstantWithValue:(half_float::half)value name:(NSString *)name;

/// Constant value.
@property (readonly, nonatomic) NSData *value;

/// Constant type.
@property (readonly, nonatomic) MTLDataType type;

/// Constant name.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
