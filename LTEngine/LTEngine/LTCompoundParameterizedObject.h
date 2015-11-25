// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTPrimitiveParameterizedObject;

/// Represents mapping from key to primitive parameterized objects.
typedef NSDictionary<NSString *, id<LTPrimitiveParameterizedObject>>
    LTKeyToPrimitiveParameterizedObject;

/// Represents mutable mapping from key to primitive parameterized objects.
typedef NSMutableDictionary<NSString *, id<LTPrimitiveParameterizedObject>>
    LTMutableKeyToPrimitiveParameterizedObject;

/// Univariately parameterized object constituted by a compound of primitive parameterized objects.
@interface LTCompoundParameterizedObject : NSObject <LTParameterizedObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c mapping mapping keys to primitive parameterized objects
/// used for value computation. The mapping must have at least one key. All primitive parameterized
/// objects of the provided \c mapping must have the same intrinsic parametric range, i.e. their
/// \c minParametricValue and their \c maxParametricValue, respectively, must be identical. The
/// initialized instance has the same intrinsic parametric range as the provided primitive
/// parameterized objects.
- (instancetype)initWithMapping:(LTKeyToPrimitiveParameterizedObject *)mapping
    NS_DESIGNATED_INITIALIZER;

/// Mapping of keys to their corresponding primitive parameterized objects.
@property (readonly, nonatomic) LTKeyToPrimitiveParameterizedObject *mapping;

@end

NS_ASSUME_NONNULL_END
