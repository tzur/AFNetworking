// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptSubscriptionInfo, BZRReceiptValidationStatus, LTPath;

/// Interface for providing the list of purchased products, products with downloaded content, and
/// subscription information.
@protocol BZRProductsInfoProvider <NSObject>

/// Provides access to the content of \c product if it exists.
///
/// Returns a signal that sends an \c NSBundle or \c nil if the content is not available on the
/// device, or if the product has no content to be downloaded. The bundle provides access to the
/// content of the product specified by \c product. The signal completes after sending the value.
/// The signal errs an error occurred during fetching.
///
/// @return <tt>RACSignal<nullable NSBundle></tt>
- (RACSignal *)contentBundleForProduct:(NSString *)productIdentifier;

/// List of products that were purchased by the user as in-app purchases. KVO-compliant. Changes may
/// be delivered on an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *purchasedProducts;

/// List of products that were acquired by the user via subscription on the current device.
/// KVO-compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *acquiredViaSubscriptionProducts;

/// List of products that were acquired by the user. This includes in-app purchases on all devices
/// and products that the user acquired via subscription on the current device. KVO-compliant.
/// Changes may be delivered on an arbitrary thread.
///
/// @note The user isn't necessarily allowed to use the products returned by this method, for
/// example if he acquired a product via a subscription that expired. One should check
/// \c allowedProducts to get the list of products that the user is allowed to use.
@property (readonly, nonatomic) NSSet<NSString *> *acquiredProducts;

/// List of products that the user is allowed to use. KVO-compliant. Changes may be delivered on an
/// arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *allowedProducts;

/// List of products that their content is already available on the device and ready to be used.
/// Products without content will be in the list as well. KVO-compliant. Changes may be delivered on
/// an arbitrary thread.
@property (readonly, nonatomic) NSSet<NSString *> *downloadedContentProducts;

/// Subscription information of the user. KVO-compliant. Changes may be delivered on an arbitrary
/// thread.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *subscriptionInfo;

/// Status of the latest receipt validation. KVO-compliant. Changes may be delivered on an arbitrary
/// thread.
@property (readonly, nonatomic, nullable) BZRReceiptValidationStatus *receiptValidationStatus;

/// AppStore locale. KVO-compliant. Changes may be delivered on an arbitrary thread.
@property (readonly, nonatomic, nullable) NSLocale *appStoreLocale;

@end

NS_ASSUME_NONNULL_END
