// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelector.h"

#import "BZRProduct+StoreKit.h"
#import "NSString+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRLocaleBasedVariantSelector ()

/// Dictionary that maps fetched product identifier to \c BZRProduct.
@property (readonly, nonatomic) BZRProductDictionary *productDictionary;

/// Dictionary that maps country code to variant's tier.
@property (readonly, nonatomic) NSDictionary<NSString *, NSString *> *countryToTier;

@end

@implementation BZRLocaleBasedVariantSelector

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithProductDictionary:(BZRProductDictionary *)productDictionary
    countryToTier:(NSDictionary<NSString *, NSString *> *)countryToTier {
  if (self = [super init]) {
    _productDictionary = productDictionary;
    _countryToTier = countryToTier;
  }
  return self;
}

#pragma mark -
#pragma mark BZRProductsVariantSelector
#pragma mark -

- (NSString *)selectedVariantForProductWithIdentifier:(NSString *)productIdentifier {
  BZRProduct *product = self.productDictionary[productIdentifier];
  LTParameterAssert(product, @"Got a request for variant of product that does not exist. "
                    "Identifier: %@", productIdentifier);
  NSString *countryCode =
      [product.underlyingProduct.priceLocale objectForKey:NSLocaleCountryCode];
  NSString *tier = self.countryToTier[countryCode];
  if (!tier) {
    return productIdentifier;
  }
  NSString *variantIdentifier = [productIdentifier bzr_variantWithSuffix:tier];
  return self.productDictionary[variantIdentifier] ? variantIdentifier : productIdentifier;
}

@end

NS_ASSUME_NONNULL_END
