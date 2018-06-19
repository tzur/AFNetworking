// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRProductsInfoProvider.h"

@protocol BZRTweakCollectionsProvider, BZRTweaksOverrideSubscriptionProvider;

NS_ASSUME_NONNULL_BEGIN

/// The use of this class is available only in debug mode.
#ifdef DEBUG

/// Products info provider that can be used when the app is in the debug mode. Proxies an underlying
/// provider and uses Milkshake to allow inspecting and overriding some of the subscription
/// properties in runtime.
@interface BZRTweaksProductsInfoProvider : NSObject <BZRProductsInfoProvider>

/// Initializes with an underlying \c productInfoProvider used to read the original subscription
/// info from the device, a \c subscriptionCollectionsProvider which is used to display
/// tweaks, an \c overrideSubscriptionProvider which provides an overriding subscription and a
/// signal specifying which subscription should be used, and a generic subscription to be used
/// when the subscription source is \c BZRTweaksSubscriptionSourceGenericActive.
- (instancetype)initWithProductInfoProvider:(id<BZRProductsInfoProvider>)underlyingProvider
    subscriptionCollectionsProvider:(id<BZRTweakCollectionsProvider>)subscriptionCollectionsProvider
    overrideSubscriptionProvider:
    (id<BZRTweaksOverrideSubscriptionProvider>)overrideSubscriptionProvider
    genericActiveSubscription:(BZRReceiptSubscriptionInfo *)genericActiveSubscription
    NS_DESIGNATED_INITIALIZER;

/// Initializes with an underlying \c productInfoProvider, used to read the original subscription
/// info from the device and to create a \c BZRTweaksSubscriptionCollectionsProvider which is used
/// as both the \c subscriptionCollectionsProvider and the \c overrideSubscriptionProvider.
/// The generic active subscription is created by a category on BZRReceiptSubscriptionInfo.
- (instancetype)initWithProvider:(id<BZRProductsInfoProvider>)underlyingProvider;

- (instancetype)init NS_UNAVAILABLE;

@end

#endif

NS_ASSUME_NONNULL_END
