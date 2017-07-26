// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

@protocol LABTweakCollectionsProvider;

@class FBTweakCategory;

/// Implementers of this protocol provide FBTweak categories.
@protocol LABTweakCategoriesProvider <NSObject>

/// All Tweak categories available from this provider. Due to the non reactive design of FBTweaks UI
/// the array must persist the same objects while the Tweaks UI is displayed, as newly added
/// categories are ignored during this phase. \c FBTweakCategory objects are mutable and any changes
/// to their contents must be committed to the categories to avoid unexpected behaviour during the
/// display of the Tweaks UI.
@property (readonly, nonatomic) NSArray<FBTweakCategory *> *categories;

@end

/// Default implementation of \c LABTweakCategoriesProvider. This class multiplexes
/// \c LABTweakCollectionsProvider objects into a category for each. Each category contains the
/// \c collections of the corresponding \c LABTweakCollectionsProvider.
///
/// A settings category is provided as well. Each Tweak collection in the category has one boolean
/// tweak, used to update a provider, a tweak for indicating the update status and a tweak for
/// resetting a provider.
///
/// @note if an \c LABTweakCollectionsProvider does not implement the \c updateCollections method,
/// there will be no update tweak in the "Settings" category.
@interface LABTweakCategoriesProvider : NSObject <LABTweakCategoriesProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c providers dictionary that maps category names to collections
/// providers.
- (instancetype)initWithProviders:
    (NSDictionary<NSString *, id<LABTweakCollectionsProvider>> *)providers
    NS_DESIGNATED_INITIALIZER;

/// Category of settings tweaks. This object never changes - only the state of the inner tweaks.
@property (readonly, nonatomic) FBTweakCategory *settingsCategory;

/// Categories associated with the \c providers. Sorted by the category names. This object never
/// changes - only the state of the inner collections and tweaks.
@property (readonly, nonatomic) NSArray<FBTweakCategory *> *providerCategories;

@end

NS_ASSUME_NONNULL_END
