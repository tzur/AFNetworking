// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

#import "BZRDummyContentFetcher.h"
#import "BZRProduct+StoreKit.h"

SpecBegin(BZRProduct)

context(@"BZRModel", ^{
  it(@"should correctly specifiy optional properties", ^{
    NSSet<NSString *> *optionalProperties = [BZRProduct optionalPropertyKeys];

    expect(optionalProperties.count).to.equal(11);
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, contentFetcherParameters));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, priceInfo));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, isSubscribersOnly));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, preAcquiredViaSubscription));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, preAcquired));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, variants));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, discountedProducts));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, fullPriceProductIdentifier));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, enablesProducts));
  });
});

context(@"MTLModel", ^{
  it(@"should not include the underlying StoreKit product in the propertyKeys", ^{
    expect([BZRProduct propertyKeys])
        .toNot.contain(@instanceKeypath(BZRProduct, underlyingProduct));
  });

  it(@"should include the underlying StoreKit product in the dictionary value", ^{
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRProduct, identifier): @"foo",
      @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
      @instanceKeypath(BZRProduct, underlyingProduct): underlyingProduct
    };

    auto product = [[BZRProduct alloc] initWithDictionary:dictionaryValue error:nil];

    expect(product.dictionaryValue[@keypath(product, underlyingProduct)])
        .to.equal(underlyingProduct);
  });

  it(@"should not include isSubscriptionProduct in the propertyKeys", ^{
    expect([BZRProduct propertyKeys])
        .toNot.contain(@instanceKeypath(BZRProduct, isSubscriptionProduct));
  });
});

context(@"JSON serialization" , ^{
  it(@"should correctly serialize BZRProduct instance to JSON dictionary", ^{
    BZRDummyContentFetcherParameters *contentFetcherParameters =
        [[BZRDummyContentFetcherParameters alloc] initWithValue:@"bar"];
    NSDictionary *dictionaryValue = @{
      @instanceKeypath(BZRProduct, identifier): @"foo",
      @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
      @instanceKeypath(BZRProduct, isSubscribersOnly): @YES,
      @instanceKeypath(BZRProduct, preAcquiredViaSubscription): @YES,
      @instanceKeypath(BZRProduct, preAcquired): @YES,
      @instanceKeypath(BZRProduct, contentFetcherParameters): contentFetcherParameters,
      @instanceKeypath(BZRProduct, variants): @[@"TierA", @"TierB"],
      @instanceKeypath(BZRProduct, enablesProducts): @[@"foo.bar", @"baz"]
    };

    NSError *error = nil;
    BZRProduct *product = [[BZRProduct alloc] initWithDictionary:dictionaryValue error:&error];
    expect(error).to.beNil();

    NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:product];
    expect(jsonDictionary[@instanceKeypath(BZRProduct, productType)]).to.equal(@"nonConsumable");
    expect(jsonDictionary[@instanceKeypath(BZRProduct, contentFetcherParameters)])
        .to.equal([MTLJSONAdapter JSONDictionaryFromModel:contentFetcherParameters]);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, isSubscribersOnly)]).to.equal(@YES);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, preAcquiredViaSubscription)]).to.equal(YES);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, preAcquired)]).to.equal(YES);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, variants)]).to.equal(@[@"TierA", @"TierB"]);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, enablesProducts)])
        .to.equal(@[@"foo.bar", @"baz"]);
  });

  it(@"should correctly deserialize from JSON dictionary to BZRProduct", ^{
    NSDictionary *jsonDictionary = @{
      @"identifier": @"id",
      @"productType": @"nonRenewingSubscription",
      @"contentFetcherParameters": @{
        @"type": NSStringFromClass([BZRDummyContentFetcher class]),
        @"value": @"foo"
      },
      @"isSubscribersOnly": @NO,
      @"variants": @[@"TierA", @"TierB"],
      @"enablesProducts": @[@"foo.bar", @"baz"]
    };
    BZRDummyContentFetcherParameters *expectedParameters =
        [[BZRDummyContentFetcherParameters alloc] initWithValue:@"foo"];

    NSError *error = nil;
    BZRProduct *product = [MTLJSONAdapter modelOfClass:[BZRProduct class]
                                    fromJSONDictionary:jsonDictionary error:&error];
    expect(error).to.beNil();
    expect(product.identifier).to.equal(@"id");
    expect(product.productType).to.equal($(BZRProductTypeNonRenewingSubscription));
    expect(product.contentFetcherParameters).to.equal(expectedParameters);
    expect(product.isSubscribersOnly).to.equal(NO);
    expect(product.preAcquiredViaSubscription).to.equal(NO);
    expect(product.preAcquired).to.equal(NO);
    expect(product.variants).to.equal(@[@"TierA", @"TierB"]);
    expect(product.enablesProducts).to.equal(@[@"foo.bar", @"baz"]);
  });

  it(@"should include the underlying product in the dictionary value if it exists", ^{
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    NSDictionary *dictionaryValue = @{
        @instanceKeypath(BZRProduct, identifier): @"foo",
        @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
        @instanceKeypath(BZRProduct, underlyingProduct): underlyingProduct
    };
    BZRProduct *product = [[BZRProduct alloc] initWithDictionary:dictionaryValue error:nil];

    expect(product).toNot.beNil();
    expect(product.dictionaryValue[@keypath(product, underlyingProduct)])
        .to.beIdenticalTo(underlyingProduct);
    });
});

SpecEnd
