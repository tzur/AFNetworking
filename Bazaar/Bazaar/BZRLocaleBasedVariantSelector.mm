// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelector.h"

#import "BZRProduct+SKProduct.h"
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
  NSString *tier = self.countryToTier[product.bzr_underlyingProduct.priceLocale.countryCode];
  if (!tier) {
    return productIdentifier;
  }
  NSString *variantIdentifier = [productIdentifier bzr_variantWithSuffix:tier];
  return self.productDictionary[variantIdentifier] ? variantIdentifier : productIdentifier;
}

- (NSString *)baseProductForProductWithIdentifier:(NSString *)productIdentifier {
  BZRProduct *product = self.productDictionary[productIdentifier];
  LTParameterAssert(product, @"Got a request for base product of product that does not exist. "
                    "Identifier: %@", productIdentifier);
  NSString *baseIdentifier = [productIdentifier bzr_baseProductIdentifier];
  LTAssert(self.productDictionary[baseIdentifier], @"Got a request for base product that does not "
           "exist. This is probably a typo in the base or the variant identifiers. The base "
           "identifier is: %@. The variant identifier is: %@.", baseIdentifier, productIdentifier);
  return baseIdentifier;
}

@end

NS_ASSUME_NONNULL_END
