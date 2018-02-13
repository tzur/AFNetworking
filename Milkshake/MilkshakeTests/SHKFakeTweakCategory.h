// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKTweakCategory.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake category to aid in testing since \c tweakCollections is KVO-compliant. Implements all
/// methods.
@interface SHKFakeTweakCategory : NSObject <SHKTweakCategory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c name, \c tweakCollections, and \c nil updateSignal.
- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections;

/// Initializes with \c name, \c tweakCollections, and \c updateSignal to return in the
/// \c update method.
- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections
                updateSignal:(nullable RACSignal *)updateSignal;

/// Tweak collections in this category. KVO-compliant.
@property (readwrite, nonatomic) NSArray<FBTweakCollection *> *tweakCollections;

/// To be returned in the \c update method.
@property (readonly, nonatomic, nullable) RACSignal *updateSignal;

/// \c YES if the \c reset method was invoked.
@property (nonatomic) BOOL resetCalled;

@end

/// Fake category to aid in testing since \c tweakCollections is KVO-compliant. Does not implement
/// the \c update and \c reset methods.
@interface SHKPartialFakeTweakCategory : NSObject <SHKTweakCategory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c name, \c tweakCollections, and \c nil updateSignal.
- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections;

@end

NS_ASSUME_NONNULL_END
