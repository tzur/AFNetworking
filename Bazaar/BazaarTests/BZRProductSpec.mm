// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

#import "BZRContentFetcherParameters.h"

/// Dummy concrete implemenation of \c BZRContentFetcherParameters used for testing.
@interface BZRDummyContentFetcherParameters : BZRContentFetcherParameters

/// Value to be passed to content fetcher.
@property (readonly, nonatomic) NSString *value;

@end

@implementation BZRDummyContentFetcherParameters

- (instancetype)initWithValue:(NSString *)value {
  if (self = [super init]) {
    _value = [value copy];
  }
  return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRDummyContentFetcherParameters, value): @"value"
  };
}

@end

SpecBegin(BZRProduct)

context(@"initialization", ^{
  it(@"should correctly specifiy nullable properties", ^{
    NSSet<NSString *> *nullableProperties = [BZRProduct nullablePropertyKeys];

    expect(nullableProperties.count).to.equal(3);
    expect(nullableProperties).to.contain(@instanceKeypath(BZRProduct, contentFetcherParameters));
    expect(nullableProperties).to.contain(@instanceKeypath(BZRProduct, priceInfo));
    expect(nullableProperties).to.contain(@instanceKeypath(BZRProduct, purchaseStatus));
  });
});

context(@"conversion" , ^{
  it(@"should correctly convert BZRProduct instance to JSON dictionary", ^{
    BZRDummyContentFetcherParameters *contentFetcherParameters =
        [[BZRDummyContentFetcherParameters alloc] initWithValue:@"bar"];
    NSDictionary *dictionaryValue =  @{
      @instanceKeypath(BZRProduct, identifier): @"foo",
      @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
      @instanceKeypath(BZRProduct, purchaseStatus): $(BZRProductPurchaseStatusPurchased),
      @instanceKeypath(BZRProduct, contentFetcherParameters): contentFetcherParameters
    };

    NSError *error = nil;
    BZRProduct *product = [[BZRProduct alloc] initWithDictionary:dictionaryValue error:&error];
    expect(error).to.beNil();

    NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:product];
    expect(jsonDictionary[@"productType"]).to.equal(@"nonConsumable");
    expect(jsonDictionary[@"purchaseStatus"]).to.equal(@"purchased");
    expect(jsonDictionary[@"contentFetcherParameters"])
        .to.equal([MTLJSONAdapter JSONDictionaryFromModel:contentFetcherParameters]);
  });

  it(@"should correctly convert from JSON dictionary to BZRProduct", ^{
    NSDictionary *jsonDictionary = @{
      @"identifier": @"id",
      @"productType": @"nonRenewingSubscription",
      @"purchaseStatus": @"purchased",
      @"contentFetcherParameters": @{
        @"type": NSStringFromClass([BZRDummyContentFetcherParameters class]),
        @"value": @"foo"
      }
    };
    BZRDummyContentFetcherParameters *expectedParameters =
        [[BZRDummyContentFetcherParameters alloc] initWithValue:@"foo"];

    NSError *error = nil;
    BZRProduct *product = [MTLJSONAdapter modelOfClass:[BZRProduct class]
                                    fromJSONDictionary:jsonDictionary error:&error];
    expect(error).to.beNil();
    expect(product.identifier).to.equal(@"id");
    expect(product.productType).to.equal($(BZRProductTypeNonRenewingSubscription));
    expect(product.purchaseStatus).to.equal($(BZRProductPurchaseStatusPurchased));
    expect(product.contentFetcherParameters).to.equal(expectedParameters);
  });
});

SpecEnd
