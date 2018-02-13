// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

@class FBTweakCollection;

/// A named array of Tweak collecrions. A Tweak category the highest-level container that can be
/// created (meaning this is the highest in the tweak model hierarchy).
///
/// This protocol allows the implementation of reactive, updated-on-demand tweak collections. It is
/// a simpler version of the \c FBTweakCategory class, which shares the same basic traits.
///
/// @see FBTweakCategory
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

NS_ASSUME_NONNULL_END
