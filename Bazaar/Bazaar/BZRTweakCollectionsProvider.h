// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

@class FBTweakCollection;

NS_ASSUME_NONNULL_BEGIN

/// Protocol that defines a provider of \c FBTweakCollection array, which can be used to populate
/// \c FBTweakCategory.
@protocol BZRTweakCollectionsProvider <NSObject>

/// Collection array, used to populate an \c FBTweakCategory. KVO-compliant.
@property (readonly, nonatomic) NSArray<FBTweakCollection *> *collections;

@end

NS_ASSUME_NONNULL_END
