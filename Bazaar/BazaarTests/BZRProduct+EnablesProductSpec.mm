// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+EnablesProduct.h"

#import "BZRTestUtils.h"

SpecBegin(BZRProduct_EnablesProduct)

context(@"enables product", ^{
  context(@"subscription product", ^{
    __block BZRProduct *product;

    beforeEach(^{
      product = [[BZRProduct alloc] initWithDictionary:@{
        @instanceKeypath(BZRProduct, productType): $(BZRProductTypeRenewableSubscription),
        @instanceKeypath(BZRProduct, identifier): @"subscription"
      } error:nil];
    });

    it(@"should return YES if enablesProducts is nil", ^{
      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(YES);
    });

    it(@"should return NO if enablesProducts is an empty array", ^{
      product = [product modelByOverridingProperty:@keypath(product, enablesProducts)
                                         withValue:@[]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(NO);
    });

    it(@"should return YES if enablesProducts contains a matching prefix", ^{
      product = [product modelByOverridingProperty:@keypath(product, enablesProducts)
                                         withValue:@[@"foo"]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(YES);
      expect([product enablesProductWithIdentifier:@"foo-bar"]).to.equal(YES);
    });

    it(@"should return NO if enablesProducts contains no matching prefix", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[@"bar"]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(NO);
      expect([product enablesProductWithIdentifier:@"foo-bar"]).to.equal(NO);
    });

    it(@"should return YES for any product if enablesProducts contains an empty string", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[@"foo", @""]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(YES);
      expect([product enablesProductWithIdentifier:@"bar"]).to.equal(YES);
    });
  });

  context(@"non-subscription product", ^{
    __block BZRProduct *product;

    beforeEach(^{
      product = [[BZRProduct alloc] initWithDictionary:@{
        @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
        @instanceKeypath(BZRProduct, identifier): @"feature"
      } error:nil];
    });

    it(@"should return NO if enablesProducts is nil", ^{
      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(NO);
    });

    it(@"should return NO if enablesProducts is an empty array", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(NO);
    });

    it(@"should return YES if enablesProducts contains a matching prefix", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[@"foo"]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(YES);
      expect([product enablesProductWithIdentifier:@"foo-bar"]).to.equal(YES);
    });

    it(@"should return NO if enablesProducts contains no matching prefix", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[@"bar"]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(NO);
      expect([product enablesProductWithIdentifier:@"foo-bar"]).to.equal(NO);
    });

    it(@"should return YES for any product if enablesProducts contains an empty string", ^{
      product = [product modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
                                         withValue:@[@"foo", @""]];

      expect([product enablesProductWithIdentifier:@"foo"]).to.equal(YES);
      expect([product enablesProductWithIdentifier:@"bar"]).to.equal(YES);
    });
  });
});

SpecEnd
