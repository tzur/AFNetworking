// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelector.h"

#import "BZRProduct+StoreKit.h"
#import "BZRTestUtils.h"

SpecBegin(BZRLocaleBasedVariantSelector)

__block BZRProduct *product;
__block BZRProduct *variant;
__block NSMutableDictionary<NSString *, BZRProduct *> *productDictionary;
__block NSDictionary<NSString *, NSString *> *countryToTier;
__block BZRLocaleBasedVariantSelector *variantSelector;

beforeEach(^{
  product = BZRProductWithIdentifier(@"foo");
  variant = BZRProductWithIdentifier(@"foo.Variant.TierA");
  productDictionary = [@{
    @"foo": product,
    @"foo.Variant.TierA": variant
  } mutableCopy];

  countryToTier = @{
    @"RU": @"TierA",
    @"EN": @"TierC"
  };
  variantSelector =
      [[BZRLocaleBasedVariantSelector alloc] initWithProductDictionary:productDictionary
                                                         countryToTier:countryToTier];
});

context(@"getting variant for products", ^{
  it(@"should raise exception if product doesn't exist", ^{
    expect(^{
      [variantSelector selectedVariantForProductWithIdentifier:@"bar"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return same identifier if country code was not found", ^{
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    OCMStub([underlyingProduct priceLocale])
        .andReturn([NSLocale localeWithLocaleIdentifier:@"fr_BE"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
         withValue:underlyingProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"]).to.equal(@"foo");
  });

  it(@"should return same identifier if variant was not found", ^{
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    OCMStub([underlyingProduct priceLocale])
        .andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
         withValue:underlyingProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"]).to.equal(@"foo");
  });

  it(@"should return variant of product", ^{
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    OCMStub([underlyingProduct priceLocale])
        .andReturn([NSLocale localeWithLocaleIdentifier:@"ru_RU"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
         withValue:underlyingProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"])
        .to.equal(@"foo.Variant.TierA");
  });
});

SpecEnd
