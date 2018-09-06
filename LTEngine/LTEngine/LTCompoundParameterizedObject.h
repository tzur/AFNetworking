// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTValueObject.h>

#import "LTParameterizedValueObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTBasicParameterizedObject;

/// Pair of key and \c id<LTBasicParameterizedObject>.
@interface LTKeyBasicParameterizedObjectPair : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Returns a new instance with the given \c key and the given \c basicParameterizedObject.
+ (instancetype)pairWithKey:(NSString *)key
   basicParameterizedObject:(id<LTBasicParameterizedObject>)basicParameterizedObject;

/// Key.
@property (readonly, nonatomic) NSString *key;

/// Basic parameterized object.
@property (readonly, nonatomic) id<LTBasicParameterizedObject> basicParameterizedObject;

@end

/// Ordered collection of pairs consisting of a key and a corresponding basic parameterized object.
typedef NSArray<LTKeyBasicParameterizedObjectPair *> LTKeyToBaseParameterizedObject;

/// Univariately parameterized value object constituted by a compound of basic parameterized
/// objects.
@interface LTCompoundParameterizedObject : NSObject <LTParameterizedValueObject>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a copy of the given \c mapping mapping keys to basic parameterized objects
/// used for value computation. The mapping must have at least one key. All basic parameterized
/// objects of the provided \c mapping must have the same intrinsic parametric range, i.e. their
/// \c minParametricValue and their \c maxParametricValue, respectively, must be identical. The
/// initialized instance has the same intrinsic parametric range as the provided basic parameterized
/// objects. The keys of the given \c mapping are used as the \c parameterizationKeys of the
/// returned instance, in the given order.
///
/// @note The given \c mapping is used as is without copying.
- (instancetype)initWithMapping:(LTKeyToBaseParameterizedObject *)mapping NS_DESIGNATED_INITIALIZER;

/// Mapping of keys to their corresponding basic parameterized objects.
@property (readonly, nonatomic) LTKeyToBaseParameterizedObject *mapping;

@end

NS_ASSUME_NONNULL_END
