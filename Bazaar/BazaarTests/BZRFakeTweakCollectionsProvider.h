// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweakCollectionsProvider.h"

@class FBTweakCollection;

NS_ASSUME_NONNULL_BEGIN

/// A fake \c BZRTweakCollectionsProvider with readwrite access to the \c collections property,
/// which is initialized to an empty array.
@interface BZRFakeTweakCollectionsProvider : NSObject <BZRTweakCollectionsProvider>

/// Redeclare as readwrite.
@property (readwrite, nonatomic) NSArray<FBTweakCollection *> *collections;

@end

NS_ASSUME_NONNULL_END
