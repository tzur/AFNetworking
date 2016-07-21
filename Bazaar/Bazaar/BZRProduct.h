// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProductContentDescriptor, BZRProductPriceInfo;

/// Possible values for types of products, corresponding to products purchasable in itunes
/// connect.
LTEnumDeclare(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

LTEnumDeclare(NSUInteger, BZRProductPurchaseStatus,
  BZRProductPurchaseStatusNotPurchased,
  BZRProductPurchaseStatusAcquiredViaSubscription,
  BZRProductPurchaseStatusPurchased
);

/// Represents a single in-app product.
@interface BZRProduct : BZRModel <MTLJSONSerializing>

/// The AppStore unique identifier, used to uniquely identify the product.
@property (readonly, nonatomic) NSString *identifier;

/// Product type.
@property (readonly, nonatomic) BZRProductType *productType;

/// Describes the way to fetch the content that needed in order to use the product. \c nil if no
/// content is needed to be fetched.
@property (readonly, nonatomic, nullable) BZRProductContentDescriptor *descriptor;

/// Holds the price and the locale of the product.
@property (readonly, nonatomic, nullable) BZRProductPriceInfo *priceInfo;

/// \c BZRProductPurchaseStatusNotPurchased if the product was not purchased,
/// \c BZRProductPurchaseStatusAcquiredViaSubscription if it was acquired via subscription, and
/// \c BZRProductPurchaseStatusPurchased if the product was purchased without subscription.
@property (readonly, nonatomic) BZRProductPurchaseStatus *purchaseStatus;

@end

NS_ASSUME_NONNULL_END
