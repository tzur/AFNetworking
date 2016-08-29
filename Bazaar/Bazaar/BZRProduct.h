// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRContentFetcherParameters, BZRProductPriceInfo;

/// Possible values for types of products, corresponding to products purchasable in itunes
/// connect.
LTEnumDeclare(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

/// Possible values for the purchase status of a product.
LTEnumDeclare(NSUInteger, BZRProductPurchaseStatus,
  /// The product was not purchased.
  BZRProductPurchaseStatusNotPurchased,
  /// The product was acquired while the user was a subscriber.
  BZRProductPurchaseStatusAcquiredViaSubscription,
  /// The product was purchased while the user was not a subscriber.
  BZRProductPurchaseStatusPurchased
);

/// Represents a single in-app product.
@interface BZRProduct : BZRModel <MTLJSONSerializing>

/// Returns a new \c BZRProduct with \c contentProviderParameters set to given
/// \c contentProviderParameters.
- (BZRProduct *)productWithContentFetcherParameters:
    (BZRContentFetcherParameters *)contentFetcherParameters error:(NSError **)error;

/// The AppStore unique identifier, used to uniquely identify the product.
@property (readonly, nonatomic) NSString *identifier;

/// Product type.
@property (readonly, nonatomic) BZRProductType *productType;

/// Describes the parameters needed to fetch the content of the product. \c nil if no content is
/// needed to be fetched.
@property (readonly, nonatomic, nullable) BZRContentFetcherParameters *contentFetcherParameters;

/// Holds the price and the locale of the product.
@property (readonly, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Holds the purchase status of the product.
@property (readonly, nonatomic, nullable) BZRProductPurchaseStatus *purchaseStatus;

@end

NS_ASSUME_NONNULL_END
