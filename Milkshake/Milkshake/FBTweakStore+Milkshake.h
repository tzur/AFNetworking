// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweakStore.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SHKTweakCategory;

/// Allows using Milkshake objects with \c FBTweakStore.
@interface FBTweakStore (Milkshake)

/// Adds the given \c category to the receiver.
///
/// \c SHKTweakCategoryAdapter is used as an adapter between \c category and the FBTweakCategory
/// class.
- (void)shk_addTweakCategory:(id<SHKTweakCategory>)category;

@end

NS_ASSUME_NONNULL_END
