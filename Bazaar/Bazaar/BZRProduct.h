// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRBillingPeriod, BZRContentFetcherParameters, BZRProductPriceInfo,
    BZRSubscriptionIntroductoryDiscount;

#pragma mark -
#pragma mark BZRProductType
#pragma mark -

/// Possible values for types of products, corresponding to products purchasable in itunes
/// connect.
LTEnumDeclare(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

#pragma mark -
#pragma mark BZRProduct
#pragma mark -

/// Represents a single in-app product.
@interface BZRProduct : BZRModel <MTLJSONSerializing>

/// Returns a new \c BZRProduct with \c contentFetcherParameters set to given
/// \c contentFetcherParameters.
- (BZRProduct *)productWithContentFetcherParameters:
    (BZRContentFetcherParameters *)contentFetcherParameters error:(NSError **)error;

/// The AppStore unique identifier, used to uniquely identify the product.
@property (readonly, nonatomic) NSString *identifier;

/// Product type.
@property (readonly, nonatomic) BZRProductType *productType;

/// Price information for the product. \c nil if price information is not available.
@property (readonly, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Billing period of the product. \c nil if product is not a renewable subscription or if the
/// information is not available.
@property (readonly, nonatomic, nullable) BZRBillingPeriod *billingPeriod;

/// Introductory discount of the product. \c nil if product is not a renewable subscription, the
/// product offers no introductory discount or if the information is not available.
///
/// @note For introductory discount offering guidelines read this document by Apple:
/// https://developer.apple.com/documentation/storekit/in_app_purchase/offering_introductory_prices_in_your_app?language=objc.
@property (readonly, nonatomic, nullable) BZRSubscriptionIntroductoryDiscount *introductoryDiscount;

/// Describes the parameters needed to fetch the content of the product. \c nil if no content is
/// needed to be fetched.
@property (readonly, nonatomic, nullable) BZRContentFetcherParameters *contentFetcherParameters;

/// \c YES if the product is for subscribers only, \c NO otherwise. Optional, the default value is
/// \c NO.
@property (readonly, nonatomic) BOOL isSubscribersOnly;

/// \c YES if the product should be always available immediately without any purchasing action,
/// \c NO otherwise. Optional, the default value is \c NO.
@property (readonly, nonatomic) BOOL preAcquired;

/// \c YES if the product should be available for subscribers immediately after purchasing a
/// subscription, \c NO otherwise. Optional, the default value is \c NO.
@property (readonly, nonatomic) BOOL preAcquiredViaSubscription;

/// Available variants of the product. \c nil signifies that the receiver is a variant itself.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *variants;

/// Identifiers of discounted variants of the product. Each entry is the full identifier of the
/// discounted product. \c nil signifies that the receiver is a discount or that it has no
/// discounts.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *discountedProducts;

/// Identifier of the product that this product is a discount variant of, or \c nil if this product
/// is not a discount variant.
@property (readonly, nonatomic, nullable) NSString *fullPriceProductIdentifier;

/// Specifies the prefix of product identifiers that should be enabled when this product is
/// purchased. If this is a subscription product, \c nil signifies that this product enables all
/// products. Otherwise, \c nil signifies that this product does not enable any other products.
/// An empty array signifies that it does not enable any other products.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *enablesProducts;

@end

NS_ASSUME_NONNULL_END
