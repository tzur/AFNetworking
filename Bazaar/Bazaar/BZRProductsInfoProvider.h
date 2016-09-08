// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptSubscriptionInfo;

/// Interface for providing the list of purchased products, products with downloaded content, and
/// subscription information. All properties are KVO-compliant.
@protocol BZRProductsInfoProvider <NSObject>

/// Returns the path to the content of the product specified by \c productIdentifier or \c nil if
/// the product has no content.
- (nullable LTPath *)pathToContentOfProduct:(NSString *)productIdentifier;

/// List of products that were purchased by the user as in-app purchases.
@property (readonly, nonatomic) NSSet<NSString *> *purchasedProducts;

/// List of products that were acquired by the user via subscription on the current device.
@property (readonly, nonatomic) NSSet<NSString *> *acquiredViaSubscriptionProducts;

/// List of products that were acquired by the user. This includes in-app purchases on all devices
/// and products that the user acquired via subscription on the current device.
///
/// @note The user isn't necessarily allowed to use the products returned by this method, for
/// example if he acquired a product via a subscription that expired. One should check
/// \c productsAllowedToBeUsed to get the list of products that the user is allowed to use.
@property (readonly, nonatomic) NSSet<NSString *> *acquiredProducts;

/// List of products that the user is allowed to use.
@property (readonly, nonatomic) NSSet<NSString *> *allowedProducts;

/// List of products that their content is already available on the device. Products
/// without content will be in the list as well.
@property (readonly, nonatomic) NSSet<NSString *> *downloadedContentProducts;

/// Subscription information of the user.
@property (readonly, nonatomic, nullable) BZRReceiptSubscriptionInfo *subscriptionInfo;

@end

NS_ASSUME_NONNULL_END
