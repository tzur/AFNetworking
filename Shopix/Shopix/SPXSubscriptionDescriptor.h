// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@protocol BZRProductsInfoProvider;

@class BZRBillingPeriod, BZRProductPriceInfo, BZRSubscriptionIntroductoryDiscount;

/// Descriptor representing a subscription product and providing information that is crucial for
/// presenting the product to the user.
@interface SPXSubscriptionDescriptor : NSObject

/// Convience method for creating an array of subscription descriptors with identifiers specify
/// by \c productIdentifiers and with a discount of \c discountPercentage.
+ (NSArray<SPXSubscriptionDescriptor *> *)
    descriptorsWithProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
    discountPercentage:(NSUInteger)discountPercentage;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c productIdentifier and \c discountPercentage set to \c 0.
/// \c productsInfoProvider is pulled from Objection.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier;

/// Initializes with the given \c productIdentifier and \c discountPercentage.
/// \c productsInfoProvider is pulled from Objection.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage;

/// Initializes with \c productIdentifier that uniquely identify the product and
/// \c discountPercentage which defines a desired fictive discount percentage for the product. Must
/// be in range <tt>[0, 100)</tt>, otherwise a \c NSInvalidArgumentException is raised.
/// \c productsInfoProvider is used to identify if a subscription is a multi-app subscription.
///
/// @see discountPercentage.
- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage
                     productsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider
    NS_DESIGNATED_INITIALIZER;

/// The subscription unique identifier.
@property (readonly, nonatomic) NSString *productIdentifier;

/// \c YES if the subscription is a multi-app subscription.
@property (readonly, nonatomic) BOOL isMultiAppSubscription;

/// Price information of the subscription product. KVO Compliant.
@property (strong, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Introductory discount of the product. \c nil if one of the following is true:
///  - The Product is not a renewable subscription.
///  - The product offers no introductory discount.
///  - The user is not eligible for such discount (see bellow Apple docs).
///  - The information is not available.
/// KVO Compliant.
///
/// @note For introductory discount offering guidelines read this document by Apple:
/// https://developer.apple.com/documentation/storekit/in-app_purchase/offering_introductory_pricing_in_your_app?language=objc
@property (strong, nonatomic, nullable) BZRSubscriptionIntroductoryDiscount *introductoryDiscount;

/// Discount percentage in range <tt>[0, 100)</tt> defines a desired fictive discount percentage for
/// the product, where the price after the discount is \c priceInfo.price. \c 0 if there is no
/// discount.
///
/// The fictive full price can be calculated as following:
/// <tt>fullPrice = price * (100 / (100 - discountPercentage))</tt>.
/// For example, if \c priceInfo.price is \c 2.5 and \c discountPercentage is \c 50 so the
/// concluded fictive full price is \c 5.
@property (readonly, nonatomic) CGFloat discountPercentage;

/// Subscription's billing period. \c nil if the subscription is one-time payment.
@property (readonly, nonatomic, nullable) BZRBillingPeriod *billingPeriod;

@end

NS_ASSUME_NONNULL_END
