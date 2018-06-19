// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRTweakCollectionsProvider.h"
#import "BZRTweaksOverrideSubscriptionProvider.h"

@protocol BZRProductsInfoProvider;

NS_ASSUME_NONNULL_BEGIN

/// Prefix for identifiers of \c FBTweaks in Bazaar.
static NSString * const kBZRTweakIdentifierPrefix = @"com.lightricks.bazaar";

/// A provider for subscription info tweaks and overriding subscription info.
/// This object provides an array of tweak collections. The first collection contains
/// a tweak that allows picking a subscription info source. Whenever the value of
/// the selected source (through that tweak) changes, the selected source will be sent on
/// \c subscriptionSourceSignal.
/// Possible scenarios for different values of \c subscriptionSourceSignal:
/// \c BZRTweaksSubscriptionSourceCustomizedSubscription:
///     The previously mentioned tweak collection will also contain a reload button, and the
///     array of collections will contain an additional collection, containing tweaks that can
///     customize the subscription info. Changes in the customization tweaks will result in
///     changes to \c overridingSubscription.
/// \c BZRTweaksSubscriptionSourceOnDevice:
///     The array of collections will contain an additional collection, containing tweaks that show
///     the details of the current subscription on the device.
/// Other values:
///     The array of collections will hold only the first collection.
@interface BZRTweaksSubscriptionCollectionsProvider : NSObject <BZRTweakCollectionsProvider,
    BZRTweaksOverrideSubscriptionProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c productsInfoProvider which is observed for changes and provides the
/// original subscription info.
- (instancetype)initWithProductsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
