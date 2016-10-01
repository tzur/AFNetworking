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
  it(@"should correctly specifiy optional properties", ^{
    NSSet<NSString *> *optionalProperties = [BZRProduct optionalPropertyKeys];

    expect(optionalProperties.count).to.equal(3);
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, contentFetcherParameters));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, priceInfo));
    expect(optionalProperties).to.contain(@instanceKeypath(BZRProduct, isSubscribersOnly));
  });
});

context(@"conversion" , ^{
  it(@"should correctly convert BZRProduct instance to JSON dictionary", ^{
    BZRDummyContentFetcherParameters *contentFetcherParameters =
        [[BZRDummyContentFetcherParameters alloc] initWithValue:@"bar"];
    NSDictionary *dictionaryValue =  @{
      @instanceKeypath(BZRProduct, identifier): @"foo",
      @instanceKeypath(BZRProduct, productType): $(BZRProductTypeNonConsumable),
      @instanceKeypath(BZRProduct, isSubscribersOnly): @YES,
      @instanceKeypath(BZRProduct, contentFetcherParameters): contentFetcherParameters
    };

    NSError *error = nil;
    BZRProduct *product = [[BZRProduct alloc] initWithDictionary:dictionaryValue error:&error];
    expect(error).to.beNil();

    NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:product];
    expect(jsonDictionary[@instanceKeypath(BZRProduct, productType)]).to.equal(@"nonConsumable");
    expect(jsonDictionary[@instanceKeypath(BZRProduct, contentFetcherParameters)])
        .to.equal([MTLJSONAdapter JSONDictionaryFromModel:contentFetcherParameters]);
    expect(jsonDictionary[@instanceKeypath(BZRProduct, isSubscribersOnly)]).to.equal(@YES);
  });

  it(@"should correctly convert from JSON dictionary to BZRProduct", ^{
    NSDictionary *jsonDictionary = @{
      @"identifier": @"id",
      @"productType": @"nonRenewingSubscription",
      @"contentFetcherParameters": @{
        @"type": NSStringFromClass([BZRDummyContentFetcherParameters class]),
        @"value": @"foo"
      },
      @"isSubscribersOnly": @NO
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
  });
});

SpecEnd
