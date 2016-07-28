// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct.h"

SpecBegin(BZRProduct)

context(@"initialization", ^{
  it(@"should correctly specifiy nullable properties", ^{
    NSSet<NSString *> *nullableProperties = [BZRProduct nullablePropertyKeys];

    expect(nullableProperties.count).to.equal(2);
    expect(nullableProperties).to.contain(@instanceKeypath(BZRProduct, descriptor));
    expect(nullableProperties).to.contain(@instanceKeypath(BZRProduct, priceInfo));
  });
});

context(@"conversion" , ^{
  it(@"should correctly convert productType and purchaseStatus from BZRProduct to JSON", ^{
    NSDictionary *productDict = @{
      @"identifier": @"id",
      @"productType": $(BZRProductTypeNonConsumable),
      @"purchaseStatus": $(BZRProductPurchaseStatusPurchased),
    };

    NSError *error = nil;
    BZRProduct *product = [[BZRProduct alloc] initWithDictionary:productDict error:&error];
    expect(error).to.beNil();

    NSDictionary *jsonDict = [MTLJSONAdapter JSONDictionaryFromModel:product];
    expect(jsonDict[@"productType"]).to.equal(@"nonConsumable");
    expect(jsonDict[@"purchaseStatus"]).to.equal(@"purchased");
  });

  it(@"should correctly convert productType and purchaseStatus from JSON to BZRProduct", ^{
    NSDictionary *JSONDict = @{
      @"identifier": @"id",
      @"productType": @"renewableSubscription",
      @"purchaseStatus": @"acquiredViaSubscription",
    };

    NSError *error = nil;
    BZRProduct *product = [MTLJSONAdapter modelOfClass:[BZRProduct class]
                                    fromJSONDictionary:JSONDict error:&error];
    expect(error).to.beNil();
    expect(product.productType).to.equal($(BZRProductTypeRenewableSubscription));
    expect(product.purchaseStatus).to.equal($(BZRProductPurchaseStatusAcquiredViaSubscription));
  });
});

SpecEnd
