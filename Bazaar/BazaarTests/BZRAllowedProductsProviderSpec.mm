// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAllowedProductsProvider.h"

#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeAggregatedReceiptValidationStatusProvider.h"
#import "BZRProduct.h"
#import "BZRProductsProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

static BZRReceiptSubscriptionInfo *BZRSubscriptionWithIdentifier(NSString *subscriptionIdentifier) {
  return [BZRReceiptSubscriptionInfo modelWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): subscriptionIdentifier,
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"bar",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): [NSDate date],
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime):
        [NSDate dateWithTimeIntervalSinceNow:1337],
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO
  } error:nil];
}

SpecBegin(BZRAllowedProductsProvider)

context(@"allowed products provider", ^{
  __block id<BZRProductsProvider> productsProvider;
  __block BZRFakeAggregatedReceiptValidationStatusProvider *validationStatusProvider;
  __block BZRFakeAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
  __block BZRAllowedProductsProvider *allowedProvider;

  __block NSString *purchasedProductIdentifier;
  __block NSString *filterProductIdentifier;
  __block NSString *nonFilterProductIdentifier;

  beforeEach(^{
    productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
    validationStatusProvider = [[BZRFakeAggregatedReceiptValidationStatusProvider alloc] init];
    acquiredViaSubscriptionProvider = [[BZRFakeAcquiredViaSubscriptionProvider alloc] init];

    purchasedProductIdentifier = @"foo";
    filterProductIdentifier = @"filters.bar";
    nonFilterProductIdentifier = @"nonFilter.baz";
    BZRProduct *purchasedProduct = BZRProductWithIdentifier(purchasedProductIdentifier);
    BZRProduct *filterProduct = BZRProductWithIdentifier(filterProductIdentifier);
    BZRProduct *nonFilterProduct = BZRProductWithIdentifier(nonFilterProductIdentifier);
    BZRProduct *fullSubscription = [BZRProductWithIdentifier(@"fullSubscription")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
        withValue:$(BZRProductTypeNonRenewingSubscription)];
    BZRProduct *partialSubscription = [[BZRProductWithIdentifier(@"partialSubscription")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
        withValue:$(BZRProductTypeNonRenewingSubscription)]
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
        withValue:@[@"filters", @"brushes"]];
    NSArray<BZRProduct *> *productList = @[
      purchasedProduct,
      filterProduct,
      nonFilterProduct,
      fullSubscription,
      partialSubscription
    ];
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);

    allowedProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:productsProvider
         validationStatusProvider:validationStatusProvider
         acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];

    validationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(purchasedProductIdentifier, NO);
  });

  it(@"should allow all acquired products if the subscription from the receipt was not found in "
     "product list", ^{
    BZRReceiptSubscriptionInfo *subscription =
        BZRSubscriptionWithIdentifier(@"notFoundSubscription");
    validationStatusProvider.receiptValidationStatus =
        [validationStatusProvider.receiptValidationStatus
         modelByOverridingPropertyAtKeypath:
         @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
         withValue:subscription];
    NSSet<NSString *> *acquiredViaSubscriptionProducts =
        [NSSet setWithObjects:filterProductIdentifier, nonFilterProductIdentifier, nil];
    acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
        acquiredViaSubscriptionProducts;

    NSArray<NSString *> *expectedAllowedProducts =
        @[purchasedProductIdentifier, filterProductIdentifier, nonFilterProductIdentifier];
    expect(allowedProvider.allowedProducts).to.equal([NSSet setWithArray:expectedAllowedProducts]);
  });

  it(@"should return empty set if the receipt is nil", ^{
    validationStatusProvider.receiptValidationStatus =
        [BZRReceiptValidationStatus modelWithDictionary:@{
          @instanceKeypath(BZRReceiptValidationStatus, isValid): @NO,
          @instanceKeypath(BZRReceiptValidationStatus, error): $(BZRReceiptValidationErrorUnknown),
          @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date]
        } error:NULL];

    expect(allowedProvider.allowedProducts).to.equal([NSSet set]);
  });

  it(@"should return only purchased products if the product list is empty", ^{
    productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[]]);

    acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
        [NSSet setWithObject:filterProductIdentifier];
    allowedProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:productsProvider
         validationStatusProvider:validationStatusProvider
         acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];

    expect(allowedProvider.allowedProducts).to
        .equal([NSSet setWithObject:purchasedProductIdentifier]);
  });

  it(@"should return purchased products and acquired products if failed to fetch product list and "
     "the user has an active subscription", ^{
    NSError *fetchingError = [NSError lt_errorWithCode:1337];
    productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:fetchingError]);

    acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
        [NSSet setWithObject:filterProductIdentifier];
    allowedProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:productsProvider
         validationStatusProvider:validationStatusProvider
         acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];

    expect(allowedProvider.allowedProducts).to
        .equal([NSSet setWithObjects:purchasedProductIdentifier, filterProductIdentifier, nil]);
  });

  it(@"should return only purchased product if failed to fetch product list and the user has no "
     "active subscription", ^{
    NSError *fetchingError = [NSError lt_errorWithCode:1337];
    validationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(purchasedProductIdentifier, YES);
    productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:fetchingError]);

    acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
        [NSSet setWithObject:filterProductIdentifier];
    allowedProvider =
        [[BZRAllowedProductsProvider alloc] initWithProductsProvider:productsProvider
         validationStatusProvider:validationStatusProvider
         acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];

    expect(allowedProvider.allowedProducts).to
        .equal([NSSet setWithObject:purchasedProductIdentifier]);
  });

  context(@"full subscription", ^{
    beforeEach(^{
      BZRReceiptSubscriptionInfo *subscription =
          BZRSubscriptionWithIdentifier(@"fullSubscription");
      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:
           @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
           withValue:subscription];
    });

    it(@"should allow all products that were acquired", ^{
      NSSet<NSString *> *acquiredViaSubscriptionProducts =
          [NSSet setWithObjects:filterProductIdentifier, nonFilterProductIdentifier, nil];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          acquiredViaSubscriptionProducts;

      NSArray<NSString *> *expectedAllowedProducts =
          @[purchasedProductIdentifier, filterProductIdentifier, nonFilterProductIdentifier];
      expect(allowedProvider.allowedProducts).will
          .equal([NSSet setWithArray:expectedAllowedProducts]);
    });

    it(@"should provide only the purchased products if subscription is expired", ^{
      NSString *isExiredKeypath =
          @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription.isExpired);
      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:isExiredKeypath withValue:@YES];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObjects:filterProductIdentifier, nonFilterProductIdentifier, nil];

      expect(allowedProvider.allowedProducts).to
          .equal([NSSet setWithObject:purchasedProductIdentifier]);
    });

    it(@"should not allow products that were not acquired", ^{
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:nonFilterProductIdentifier];

      NSArray<NSString *> *expectedAllowedProducts =
          @[purchasedProductIdentifier, nonFilterProductIdentifier];
      expect(allowedProvider.allowedProducts).will
          .equal([NSSet setWithArray:expectedAllowedProducts]);
    });
  });

  context(@"partial subscription", ^{
    beforeEach(^{
      BZRReceiptSubscriptionInfo *subscription =
          BZRSubscriptionWithIdentifier(@"partialSubscription");
      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:
           @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
           withValue:subscription];
    });

    it(@"should only allow products that were acquired and the subscription allows", ^{
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithArray:@[filterProductIdentifier, nonFilterProductIdentifier]];

      expect(allowedProvider.allowedProducts)
          .will.equal([NSSet setWithArray:@[purchasedProductIdentifier, filterProductIdentifier]]);
    });

    it(@"should not allow products that the subscription allows but that were not acquired", ^{
      expect(allowedProvider.allowedProducts)
          .will.equal([NSSet setWithArray:@[purchasedProductIdentifier]]);
    });
  });

  context(@"KVO-compliance", ^{
    it(@"should update when receiptValidationStatus changes", ^{
      RACSignal *allowedProductsSignal =
          [RACObserve(allowedProvider, allowedProducts) testRecorder];

      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:
           @instanceKeypath(BZRReceiptValidationStatus, receipt.inAppPurchases)
           withValue:@[]];

      expect(allowedProductsSignal).to.sendValues(@[
        [NSSet setWithObject:purchasedProductIdentifier],
        [NSSet set]
      ]);
    });

    it(@"should update when acquired via subscription products list changes", ^{
      RACSignal *allowedProductsSignal =
          [RACObserve(allowedProvider, allowedProducts) testRecorder];

      BZRReceiptSubscriptionInfo *subscription = BZRSubscriptionWithIdentifier(@"fullSubscription");
      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:
           @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
           withValue:subscription];

      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:nonFilterProductIdentifier];

      expect(allowedProductsSignal).to.sendValues(@[
        [NSSet setWithObject:purchasedProductIdentifier],
        [NSSet setWithObject:purchasedProductIdentifier],
        [NSSet setWithObjects:purchasedProductIdentifier, nonFilterProductIdentifier, nil]
      ]);
    });

    it(@"should update when product list changes", ^{
      RACSubject *subject = [RACSubject subject];
      productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
      OCMStub([productsProvider fetchProductList]).andReturn(subject);

      BZRReceiptSubscriptionInfo *subscription =
          BZRSubscriptionWithIdentifier(@"partialSubscription");
      validationStatusProvider.receiptValidationStatus =
          [validationStatusProvider.receiptValidationStatus
           modelByOverridingPropertyAtKeypath:
           @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
           withValue:subscription];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:filterProductIdentifier];
      allowedProvider =
          [[BZRAllowedProductsProvider alloc] initWithProductsProvider:productsProvider
           validationStatusProvider:validationStatusProvider
           acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];

      RACSignal *allowedProductsSignal =
          [RACObserve(allowedProvider, allowedProducts) testRecorder];

      BZRProduct *filterProduct = BZRProductWithIdentifier(filterProductIdentifier);
      BZRProduct *partialSubscription = [[BZRProductWithIdentifier(@"partialSubscription")
          modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
          withValue:$(BZRProductTypeNonRenewingSubscription)]
          modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
          withValue:@[@"brushes", @"filters"]];
      [subject sendNext:@[filterProduct, partialSubscription]];

      expect(allowedProductsSignal).to.sendValues(@[
        [NSSet setWithObject:purchasedProductIdentifier],
        [NSSet setWithArray:@[purchasedProductIdentifier, filterProductIdentifier]]
      ]);
    });
  });
});

SpecEnd
