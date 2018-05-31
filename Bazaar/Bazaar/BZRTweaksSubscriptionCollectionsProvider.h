// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweakCollectionsProvider.h"
#import "BZRTweaksOverrideSubscriptionProvider.h"

@class BZRReceiptSubscriptionInfo, FBTweakCollection;

@protocol BZRProductsInfoProvider;

NS_ASSUME_NONNULL_BEGIN

/// A provider for subscription info.
/// Always has a collection with a tweak that allows changing the subscription source, changing the
/// value of this tweak will result in a signal sent by the \c subscriptionDataSource.
/// If \c subscriptionDataSource is set to \c kOverrideSourceCustomizedSubscription, the
/// previously mentioned tweak collection will also contain a reload button. A second
/// collection, containing tweaks that can customize a subscription, will also be sent.
/// Modifications in the customization tweaks will result in changes to \c overridingSubscription.
@interface BZRTweaksSubscriptionCollectionsProvider : NSObject<BZRTweakCollectionsProvider,
    BZRTweaksOverrideSubscriptionProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c productsInfoProvider which is observed for changes and provides the
/// original subscription info.
- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
