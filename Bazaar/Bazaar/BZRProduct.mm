// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

#import "BZRBillingPeriod.h"
#import "BZRContentFetcherParameters.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductPriceInfo.h"
#import "BZRSubscriptionIntroductoryDiscount.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRProductType
#pragma mark -

LTEnumImplement(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

#pragma mark -
#pragma mark BZRProduct
#pragma mark -

@implementation BZRProduct

- (BZRProduct *)productWithContentFetcherParameters:
    (BZRContentFetcherParameters *)contentFetcherParameters
    error:(NSError * __autoreleasing *)error {
  NSMutableDictionary *productDictionary = [[self dictionaryValue] mutableCopy];
  productDictionary[@keypath(self.contentFetcherParameters)] =
      contentFetcherParameters;
  return [self initWithDictionary:productDictionary error:error];
}

#pragma mark -
#pragma mark MTLJSONSerializing
#pragma mark -

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRProduct, identifier): @"identifier",
    @instanceKeypath(BZRProduct, productType): @"productType",
    @instanceKeypath(BZRProduct, priceInfo): @"priceInfo",
    @instanceKeypath(BZRProduct, billingPeriod): @"billingPeriod",
    @instanceKeypath(BZRProduct, introductoryDiscount): @"introductoryDiscount",
    @instanceKeypath(BZRProduct, contentFetcherParameters): @"contentFetcherParameters",
    @instanceKeypath(BZRProduct, isSubscribersOnly): @"isSubscribersOnly",
    @instanceKeypath(BZRProduct, preAcquired): @"preAcquired",
    @instanceKeypath(BZRProduct, preAcquiredViaSubscription): @"preAcquiredViaSubscription",
    @instanceKeypath(BZRProduct, variants): @"variants",
    @instanceKeypath(BZRProduct, discountedProducts): @"discountedProducts",
    @instanceKeypath(BZRProduct, fullPriceProductIdentifier): @"fullPriceProductIdentifier",
    @instanceKeypath(BZRProduct, enablesProducts): @"enablesProducts"
  };
}

+ (NSValueTransformer *)billingPeriodJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[BZRBillingPeriod class]];
}

+ (NSValueTransformer *)introductoryDiscountJSONTransformer {
  return [NSValueTransformer
          mtl_JSONDictionaryTransformerWithModelClass:[BZRSubscriptionIntroductoryDiscount class]];
}

+ (NSValueTransformer *)contentFetcherParametersJSONTransformer {
  return [NSValueTransformer
          mtl_JSONDictionaryTransformerWithModelClass:[BZRContentFetcherParameters class]];
}

+ (NSValueTransformer *)productTypeJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"nonConsumable": $(BZRProductTypeNonConsumable),
    @"renewableSubscription": $(BZRProductTypeRenewableSubscription),
    @"consumable": $(BZRProductTypeConsumable),
    @"nonRenewingSubscription": $(BZRProductTypeNonRenewingSubscription)
  }];
}

#pragma mark -
#pragma mark BZRModel
#pragma mark -

+ (NSSet<NSString *> *)optionalPropertyKeys {
  static NSSet<NSString *> *optionalPropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    optionalPropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRProduct, contentFetcherParameters),
      @instanceKeypath(BZRProduct, priceInfo),
      @instanceKeypath(BZRProduct, billingPeriod),
      @instanceKeypath(BZRProduct, introductoryDiscount),
      @instanceKeypath(BZRProduct, isSubscribersOnly),
      @instanceKeypath(BZRProduct, preAcquired),
      @instanceKeypath(BZRProduct, preAcquiredViaSubscription),
      @instanceKeypath(BZRProduct, variants),
      @instanceKeypath(BZRProduct, discountedProducts),
      @instanceKeypath(BZRProduct, fullPriceProductIdentifier),
      @instanceKeypath(BZRProduct, enablesProducts)
    ]];
  });
  return optionalPropertyKeys;
}

- (NSDictionary *)dictionaryValue {
  auto mutableDictionaryValue = [[super dictionaryValue] mutableCopy];
  mutableDictionaryValue[@keypath(self, underlyingProduct)] = self.underlyingProduct;
  return [mutableDictionaryValue copy];
}

- (BOOL)isSubscriptionProduct {
  return self.productType.value == BZRProductTypeRenewableSubscription ||
      self.productType.value == BZRProductTypeNonRenewingSubscription;
}

@end

NS_ASSUME_NONNULL_END
