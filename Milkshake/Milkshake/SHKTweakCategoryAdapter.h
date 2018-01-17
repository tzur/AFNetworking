// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweakCategory.h>

NS_ASSUME_NONNULL_BEGIN

/// Allows objects expose tweaks related to it.
@protocol SHKTweakCategory <NSObject>

/// Name of the category.
@property (readonly, nonatomic) NSString *name;

/// Tweak collections in this category. KVO-compliant.
@property (readonly, nonatomic) NSArray<FBTweakCollection *> *tweakCollections;

@optional

/// Requests the category to fetch the latest tweak collections. The returned signal completes
/// when the update completes successfully or errs.
///
/// @note This may trigger a change in the \c tweakCollections property.
///
/// @note The returned signal sends values on an arbitrary thread.
- (RACSignal *)update;

/// Reset the receiver to its default state.
///
/// @note This may trigger a change in the \c tweakCollections property.
- (void)reset;

@end

/// Adapter that takes a \c SHKTweakCategory to expose as a \c FBTweakCategory.
///
/// The \c name and \c tweakCollecions properties are forwarded to the underlying
/// \c tweakCollections, as well as the \c reset method.
/// The \c updateWithCompletion method calls the \c update method in the underlying
/// \c tweakCollection, and calls the completion block according to the signal's result.
///
/// The \c addTweakCollection and \c removeTweakCollection methods do nothing.
@interface SHKTweakCategoryAdapter : FBTweakCategory

- (instancetype)initWithName:(NSString *)name NS_UNAVAILABLE;

- (instancetype)initWithName:(NSString *)name
            tweakCollections:(NSArray<FBTweakCollection *> *)tweakCollections NS_UNAVAILABLE;

/// Initializes with \c tweakCategory as the underlying category to expose as a \c FBTweakCategory.
- (instancetype)initWithTweakCategory:(id<SHKTweakCategory>)tweakCategory;

/// The underlying \c tweakCategory.
@property (readonly, nonatomic) id<SHKTweakCategory> tweakCategory;

@end

NS_ASSUME_NONNULL_END
