// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import <Milkshake/SHKTweakCategory.h>

@protocol BZRTweakCollectionsProvider;

NS_ASSUME_NONNULL_BEGIN

/// \c SHKTweakCategory that is used to display data from Bazaar or override it.
@interface BZRTweaksCategory : NSObject <SHKTweakCategory>

- (instancetype)init NS_UNAVAILABLE;

<<<<<<< HEAD
/// Initializes with the given \c providers, used as sources of \c FBTweakCollection to be merged
/// into the receiver's \c tweakCollections. \c tweakCollections is updated whenever one of the
/// \c providers updates its \c collections.
=======
/// Initializes with the given \c providers. The \c tweakCollections in the category  is updated
/// automatically whenever one of the \c providers updates its \c collections.
>>>>>>> 32037eda... BZRTweaksCategory: initial commit.
- (instancetype)initWithCollectionsProviders:(NSArray<id<BZRTweakCollectionsProvider>> *)providers
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
