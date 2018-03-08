// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

@class FBTweakStore, FBPersistentTweak, FBTweakCategory;

NS_ASSUME_NONNULL_BEGIN

/// Contains common Tweaks for all iOS applications.
@interface SHKCommonTweaks : NSObject

- (instancetype)init NS_UNAVAILABLE;

@end

/// Contains Tweak categories for application to use. Any category can be added manually to
/// \c FBTweakStore or the \c AddAllCategoriesToTweakStore to add all categories in the class to
/// the default \f FBTweakStore.
@interface SHKTweakCategoryKiosk : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Adds all the tweak categories this class offers to the default tweak store.
+ (void)addAllCategoriesToTweakStore;

/// Returns a category that contains all the Tweaks from the \c SHKCommonTweaks class.
@property (class, readonly, nonatomic) FBTweakCategory *commonTweaksCategory;

@end

NS_ASSUME_NONNULL_END
