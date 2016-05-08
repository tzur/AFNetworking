// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedValueObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTBasicParameterizedObject;

/// Represents mapping from key to basic parameterized objects.
typedef NSDictionary<NSString *, id<LTBasicParameterizedObject>> LTKeyToBaseParameterizedObject;

/// Represents mutable mapping from key to basic parameterized objects.
typedef NSMutableDictionary<NSString *, id<LTBasicParameterizedObject>>
    LTMutableKeyToBaseParameterizedObject;

/// Univariately parameterized value object constituted by a compound of basic parameterized
/// objects.
@interface LTCompoundParameterizedObject : NSObject <LTParameterizedValueObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c mapping mapping keys to basic parameterized objects
/// used for value computation. The mapping must have at least one key. All basic parameterized
/// objects of the provided \c mapping must have the same intrinsic parametric range, i.e. their
/// \c minParametricValue and their \c maxParametricValue, respectively, must be identical. The
/// initialized instance has the same intrinsic parametric range as the provided basic parameterized
/// objects.
- (instancetype)initWithMapping:(LTKeyToBaseParameterizedObject *)mapping NS_DESIGNATED_INITIALIZER;

/// Mapping of keys to their corresponding basic parameterized objects.
@property (readonly, nonatomic) LTKeyToBaseParameterizedObject *mapping;

@end

NS_ASSUME_NONNULL_END
