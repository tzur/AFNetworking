// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRLocaleBasedVariantSelector.h"

#import "BZRProduct+SKProduct.h"
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
    SKProduct *skProduct = OCMClassMock([SKProduct class]);
    OCMStub([skProduct priceLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"fr_BE"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
         withValue:skProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"]).to.equal(@"foo");
  });

  it(@"should return same identifier if variant was not found", ^{
    SKProduct *skProduct = OCMClassMock([SKProduct class]);
    OCMStub([skProduct priceLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"en_US"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
         withValue:skProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"]).to.equal(@"foo");
  });

  it(@"should return variant of product", ^{
    SKProduct *skProduct = OCMClassMock([SKProduct class]);
    OCMStub([skProduct priceLocale]).andReturn([NSLocale localeWithLocaleIdentifier:@"ru_RU"]);
    productDictionary[@"foo"] =
        [productDictionary[@"foo"]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
         withValue:skProduct];

    expect([variantSelector selectedVariantForProductWithIdentifier:@"foo"])
        .to.equal(@"foo.Variant.TierA");
  });
});

context(@"getting base products for variants", ^{
  it(@"should raise exception if product doesn't exist", ^{
    expect(^{
      [variantSelector baseProductForProductWithIdentifier:@"bar"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should return same product if Variant word couldn't be found in the product's identifier", ^{
    NSString *product = @"foo";
    expect([variantSelector baseProductForProductWithIdentifier:product]).to.equal(product);
  });

  it(@"should return same product if Variant word couldn't be found in the product's identifier", ^{
    NSString *product = @"foo";
    expect([variantSelector baseProductForProductWithIdentifier:product]).to.equal(product);
  });

  it(@"should raise exception if base product dones't exist", ^{
    productDictionary[@"bar.Variant.tierA"] = BZRProductWithIdentifier(@"bar.Variant.TierA");
    expect(^{
      [variantSelector baseProductForProductWithIdentifier:@"bar.Variant.tierA"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should return base of given variant", ^{
    expect([variantSelector baseProductForProductWithIdentifier:@"foo.Variant.TierA"])
        .to.equal(@"foo");
  });
});

SpecEnd
