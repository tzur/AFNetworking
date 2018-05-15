// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweakCollectionsProvider.h"

@class BZRReceiptSubscriptionInfo, FBTweakCollection;

@protocol BZRProductsInfoProvider;

NS_ASSUME_NONNULL_BEGIN

/// Provider of \c FBTweakCollection array, that shows subscription information from a
/// \c productInfoProvider.
@interface BZRSubscriptionCollectionsProvider : NSObject <BZRTweakCollectionsProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c BZRProductsInfoProvider which is observed for changes and provides the
/// original subscription info.
- (instancetype)initWithProductInfoProvider:(id<BZRProductsInfoProvider>)productInfoProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
