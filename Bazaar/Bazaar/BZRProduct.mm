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
    @instanceKeypath(BZRProduct, priceInfo): @"priceInfo"
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

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRProduct, contentFetcherParameters),
      @instanceKeypath(BZRProduct, priceInfo)
    ]];
  });
  
  return nullablePropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
