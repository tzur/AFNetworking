// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Used to track cross promotions of products.
@protocol SPXCrossPromotionTracker <NSObject>

/// Called with a URL of a click and a \c session that should be used to open that URL.
typedef void (^SPXCrossPromotionTrackerCompletion)(NSURLSession *session, NSURL *clickURL);

/// Tracks a cross-promotion of an app with the given \c productID. \c campaign defines the name of
/// the source that triggered the cross-promotion. \c completion is called after local tracking has
/// been done with the URL to open to allow attribution when the product is installed and run.
- (void)trackWithProductID:(NSString *)productID campaign:(NSString *)campaign
                completion:(SPXCrossPromotionTrackerCompletion)completion;

@end

/// Tracks the display of the product view controller for attribution purposes using \c tracker.
///
/// This method should be called right before presenting an \c SKStoreProductViewController, that
/// displays the product associated with \c productID. \c campaign represents the source that caused
/// the view controller to display, such as "interstitial".
///
/// @important please consult with the Marketing team when selecting a campaign name.
void SPXTrackProductDisplay(id<SPXCrossPromotionTracker> tracker, NSNumber *productID,
                            NSString *campaign, LTSuccessOrErrorBlock _Nullable completion);

/// Tracks the display of the product view controller for attribution purposes using AppsFlyer's
/// tracker.
///
/// This method should be called right before presenting an \c SKStoreProductViewController, that
/// displays the product associated with \c productID. \c campaign represents the source that caused
/// the view controller to display, such as "interstitial".
///
/// @important please consult with the Marketing team when selecting a campaign name.
void SPXTrackProductDisplay(NSNumber *productID, NSString *campaign,
                            LTSuccessOrErrorBlock _Nullable completion);

/// Extensions on top of \c SKStoreProductViewController that allow to load product details with
/// affiliate and attribution, and to track the installation of the displayed product.
///
/// Usage of this extension should be done as follows:
/// 1. Make sure that AppsFlyer's shared tracker is properly configured.
/// 2. Start loading the product. This can happen as a preloading phase, meaning that it can happen
///    long time before the next step.
/// 3. Track the display of the product.
/// 4. Present the view controller.
@interface SKStoreProductViewController (Shopix)

/// Loads the product identified by \c productID. \c campaign is reported to iTunes Analytics as the
/// source that caused the load. \c completion is called when the product load completed.
///
/// @note it's possible and recommended not to wait for \c completion until presenting the view
/// controller, since the view controller displays a loading animation until the loading has
/// completed and knows how to handle loading errors.
///
/// @important please consult with the Marketing team when selecting a campaign name.
- (void)spx_loadProductWithProductID:(NSNumber *)productID campaign:(NSString *)campaign
                          completion:(nullable LTSuccessOrErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
