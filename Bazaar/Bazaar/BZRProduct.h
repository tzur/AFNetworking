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

/// \c YES if the product is for subscribers only, \c NO otherwise. Optional, the default value is
/// \c NO.
@property (readonly, nonatomic) BOOL isSubscribersOnly;

/// \c YES if the product should be always available immediately without any purchasing action,
/// \c NO otherwise. Optional, the default value is \c NO.
@property (readonly, nonatomic) BOOL preAcquired;

/// \c YES if the product should be available for subscribers immediately after purchasing a
/// subscription, \c NO otherwise. Optional, the default value is \c NO.
@property (readonly, nonatomic) BOOL preAcquiredViaSubscription;

/// Holds the price and the locale of the product.
@property (readonly, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// Available variants of the product. \c nil signifies that the receiver is a variant itself.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *variants;

/// Identifiers of discounted variants of the product. Each entry is the full identifier of the
/// discounted product. \c nil signifies that the receiver is a discount or that it has no
/// discounts.
@property (readonly, nonatomic, nullable) NSArray<NSString *> *discountedProducts;

/// Identifier of the product that this product is a discount variant of, or \c nil if this product
/// is not a discount variant.
@property (readonly, nonatomic, nullable) NSString *fullPriceProductIdentifier;

@end

NS_ASSUME_NONNULL_END
