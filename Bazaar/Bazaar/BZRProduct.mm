// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

#import "BZRContentFetcherParameters.h"
#import "BZRProductPriceInfo.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, BZRProductType,
  BZRProductTypeNonConsumable,
  BZRProductTypeRenewableSubscription,
  BZRProductTypeConsumable,
  BZRProductTypeNonRenewingSubscription
);

@implementation BZRProduct

#pragma mark -
#pragma mark Creating new products
#pragma mark -

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
    @instanceKeypath(BZRProduct, contentFetcherParameters): @"contentFetcherParameters",
    @instanceKeypath(BZRProduct, isSubscribersOnly): @"isSubscribersOnly",
    @instanceKeypath(BZRProduct, preAcquired): @"preAcquired",
    @instanceKeypath(BZRProduct, preAcquiredViaSubscription): @"preAcquiredViaSubscription",
    @instanceKeypath(BZRProduct, priceInfo): @"priceInfo",
    @instanceKeypath(BZRProduct, variants): @"variants",
    @instanceKeypath(BZRProduct, discountedProducts): @"discountedProducts",
    @instanceKeypath(BZRProduct, fullPriceProductIdentifier): @"fullPriceProductIdentifier",
    @instanceKeypath(BZRProduct, enablesProducts): @"enablesProducts"
  };
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

@end

NS_ASSUME_NONNULL_END
