// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

#import "BZRProductContentDescriptor.h"
#import "BZRProductPriceInfo.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

LTEnumImplement(NSUInteger, BZRProductPurchaseStatus,
  BZRProductPurchaseStatusNotPurchased,
  BZRProductPurchaseStatusAcquiredViaSubscription,
  BZRProductPurchaseStatusPurchased
);

@implementation BZRProduct

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRProduct, identifier): @"identifier",
    @instanceKeypath(BZRProduct, productType): @"productType",
    @instanceKeypath(BZRProduct, descriptor): @"contentDescriptor",
    @instanceKeypath(BZRProduct, priceInfo): @"priceInfo",
    @instanceKeypath(BZRProduct, purchaseStatus): @"purchaseStatus",
  };
}

+ (NSValueTransformer *)productTypeJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"nonConsumable": $(BZRProductTypeNonConsumable),
    @"renewableSubscription": $(BZRProductTypeRenewableSubscription),
    @"consumable": $(BZRProductTypeConsumable),
    @"nonRenewingSubscription": $(BZRProductTypeNonRenewingSubscription)
  }];
}

+ (NSValueTransformer *)purchaseStatusJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"notPurchased": $(BZRProductPurchaseStatusNotPurchased),
    @"acquiredViaSubscription": $(BZRProductPurchaseStatusAcquiredViaSubscription),
    @"purchased": $(BZRProductPurchaseStatusPurchased)
  }];
}

#pragma mark -
#pragma mark BZRModel
#pragma mark -

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRProduct, descriptor),
      @instanceKeypath(BZRProduct, priceInfo),
      @instanceKeypath(BZRProduct, purchaseStatus)
    ]];
  });
  
  return nullablePropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
