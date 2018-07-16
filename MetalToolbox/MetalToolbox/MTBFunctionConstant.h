// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Value class that contains data for creating a Metal function constant.
@interface MTBFunctionConstant : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Creates a function constant with given \c value, \c type and \c name.
+ (instancetype)constantWithValue:(NSData *)value type:(MTLDataType)type name:(NSString *)name;

/// Constant value.
@property (readonly, nonatomic) NSData *value;

/// Constant type.
@property (readonly, nonatomic) MTLDataType type;

/// Constant name.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
