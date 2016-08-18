// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel+ProductPurchased.h"

#import "BZRReceiptEnvironment.h"

SpecBegin(BZRReceiptModel_ProductPurchased)

__block NSString *productId;

beforeEach(^{
  productId = @"foo";
});

context(@"checking if a product was purchased", ^{
  it(@"should return NO if purchased products is nil", ^{
    NSDictionary *dictionaryValue = @{
      @"environment": $(BZRReceiptEnvironmentSandbox)
    };
    BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:dictionaryValue error:nil];

    expect([receipt wasProductPurchased:productId]).to.beFalsy();
  });

  it(@"should return NO if product not found in purchased products", ^{
    BZRReceiptInAppPurchaseInfo *firstProduct = OCMClassMock([BZRReceiptInAppPurchaseInfo class]);
    BZRReceiptInAppPurchaseInfo *secondProduct = OCMClassMock([BZRReceiptInAppPurchaseInfo class]);
    NSArray<BZRReceiptInAppPurchaseInfo *> *inAppPurchases = @[firstProduct, secondProduct];
    NSDictionary *dictionaryValue = @{
      @"environment": $(BZRReceiptEnvironmentSandbox),
      @"inAppPurchases": inAppPurchases
    };
    BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:dictionaryValue error:nil];
    OCMStub([firstProduct productId]).andReturn(@"bar");
    OCMStub([secondProduct productId]).andReturn(@"baz");

    expect([receipt wasProductPurchased:productId]).to.beFalsy();
  });

  it(@"should return YES if product found in purchased products", ^{
    BZRReceiptInAppPurchaseInfo *firstProduct = OCMClassMock([BZRReceiptInAppPurchaseInfo class]);
    BZRReceiptInAppPurchaseInfo *secondProduct = OCMClassMock([BZRReceiptInAppPurchaseInfo class]);
    NSArray<BZRReceiptInAppPurchaseInfo *> *inAppPurchases = @[firstProduct, secondProduct];
    NSDictionary *dictionaryValue = @{
      @"environment": $(BZRReceiptEnvironmentSandbox),
      @"inAppPurchases": inAppPurchases
    };
    BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:dictionaryValue error:nil];
    OCMStub([firstProduct productId]).andReturn(productId);

    expect([receipt wasProductPurchased:productId]).to.beTruthy();
  });
});

SpecEnd
