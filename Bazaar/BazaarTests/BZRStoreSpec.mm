// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedContentFetcher.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeAllowedProductsProvider.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductPriceInfo.h"
#import "BZRProductsProvider.h"
#import "BZRProductsVariantSelector.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationParametersProvider.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

static void BZRStubProductDictionaryToReturnProduct(BZRProduct *product,
                                                    id<BZRProductsProvider> productsProvider);

static void BZRStubProductDictionaryToReturnProductWithIdentifier(NSString *productIdentifier,
    id<BZRProductsProvider> productsProvider) {
  BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
  BZRStubProductDictionaryToReturnProduct(product, productsProvider);
}

static void BZRStubProductDictionaryToReturnProductWithContent(NSString *productIdentifier,
    id<BZRProductsProvider> productsProvider) {
  BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
  BZRStubProductDictionaryToReturnProduct(product, productsProvider);
}

static void BZRStubProductDictionaryToReturnProduct(BZRProduct *product,
    id<BZRProductsProvider> productsProvider) {
  OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
}

SpecBegin(BZRStore)

__block id<BZRProductsProvider> productsProvider;
__block BZRProductContentManager *contentManager;
__block BZRCachedReceiptValidationStatusProvider *receiptValidationStatusProvider;
__block BZRCachedContentFetcher *contentFetcher;
__block BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
__block BZRStoreKitFacade *storeKitFacade;
__block BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;
__block id<BZRProductsVariantSelector> variantSelector;
__block id<BZRReceiptValidationParametersProvider> validationParametersProvider;
__block BZRFakeAllowedProductsProvider *allowedProductsProvider;
__block id<BZRProductsProvider> netherProductsProvider;
__block NSBundle *bundle;
__block RACSubject *productsProviderEventsSubject;
__block RACSubject *receiptValidationStatusProviderEventsSubject;
__block RACSubject *acquiredViaSubscriptionProviderEventsSubject;
__block RACSubject *periodicReceiptValidatorActivatorEventsSubject;
__block RACSubject *netherProductsProviderSubject;
__block RACSubject *transactionsErrorEventsSubject;
__block RACSubject *unfinishedSuccessfulTransactionsSubject;
__block BZRStoreConfiguration *configuration;
__block BZRStore *store;
__block NSString *productIdentifier;

beforeEach(^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  contentManager = OCMClassMock([BZRProductContentManager class]);
  receiptValidationStatusProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
  contentFetcher = OCMClassMock([BZRCachedContentFetcher class]);
  acquiredViaSubscriptionProvider = OCMClassMock([BZRAcquiredViaSubscriptionProvider class]);
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  periodicValidatorActivator = OCMClassMock([BZRPeriodicReceiptValidatorActivator class]);
  variantSelector = OCMProtocolMock(@protocol(BZRProductsVariantSelector));
  validationParametersProvider = OCMClassMock([BZRReceiptValidationParametersProvider class]);
  allowedProductsProvider = [[BZRFakeAllowedProductsProvider alloc] init];
  netherProductsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  bundle = OCMClassMock([NSBundle class]);
  id<BZRProductsVariantSelectorFactory> variantSelectorFactory =
      OCMProtocolMock(@protocol(BZRProductsVariantSelectorFactory));
  OCMStub([variantSelectorFactory
      productsVariantSelectorWithProductDictionary:OCMOCK_ANY error:[OCMArg anyObjectRef]])
      .andReturn(variantSelector);

  productsProviderEventsSubject = [RACSubject subject];
  receiptValidationStatusProviderEventsSubject = [RACSubject subject];
  acquiredViaSubscriptionProviderEventsSubject = [RACSubject subject];
  periodicReceiptValidatorActivatorEventsSubject = [RACSubject subject];
  netherProductsProviderSubject = [RACSubject subject];
  transactionsErrorEventsSubject = [RACSubject subject];
  unfinishedSuccessfulTransactionsSubject = [RACSubject subject];
  OCMStub([productsProvider eventsSignal])
      .andReturn(productsProviderEventsSubject);
  OCMStub([receiptValidationStatusProvider eventsSignal])
      .andReturn(receiptValidationStatusProviderEventsSubject);
  OCMStub([acquiredViaSubscriptionProvider storageErrorEventsSignal])
      .andReturn(acquiredViaSubscriptionProviderEventsSubject);
  OCMStub([periodicValidatorActivator errorEventsSignal])
      .andReturn(periodicReceiptValidatorActivatorEventsSubject);
  OCMStub([netherProductsProvider fetchProductList]).andReturn(netherProductsProviderSubject);
  OCMStub([storeKitFacade transactionsErrorEventsSignal])
      .andReturn(transactionsErrorEventsSubject);
  OCMStub([storeKitFacade unfinishedSuccessfulTransactionsSignal])
      .andReturn(unfinishedSuccessfulTransactionsSubject);

  configuration = OCMClassMock([BZRStoreConfiguration class]);
  OCMStub([configuration productsProvider]).andReturn(productsProvider);
  OCMStub([configuration contentManager]).andReturn(contentManager);
  OCMStub([configuration validationStatusProvider]).andReturn(receiptValidationStatusProvider);
  OCMStub([configuration contentFetcher]).andReturn(contentFetcher);
  OCMStub([configuration acquiredViaSubscriptionProvider])
      .andReturn(acquiredViaSubscriptionProvider);
  OCMStub([configuration storeKitFacade]).andReturn(storeKitFacade);
  OCMStub([configuration periodicValidatorActivator]).andReturn(periodicValidatorActivator);
  OCMStub([configuration variantSelectorFactory]).andReturn(variantSelectorFactory);
  OCMStub([configuration validationParametersProvider]).andReturn(validationParametersProvider);
  OCMStub([configuration allowedProductsProvider]).andReturn(allowedProductsProvider);
  OCMStub([configuration netherProductsProvider]).andReturn(netherProductsProvider);

  store = [[BZRStore alloc] initWithConfiguration:configuration];
  productIdentifier = @"foo";
});

context(@"initial receipt validation", ^{
  it(@"should fetch receipt on initialization if receipt validation status is nil", ^{
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];

    OCMVerifyAll((id)receiptValidationStatusProvider);
  });

  it(@"should not fetch receipt on initialization if receipt validation status is not nil", ^{
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(OCMClassMock([BZRReceiptValidationStatus class]));

    store = [[BZRStore alloc] initWithConfiguration:configuration];
  });

  it(@"should send error event if initial receipt validation failed", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    LLSignalTestRecorder *eventsRecorder = [[store eventsSignal] testRecorder];

    expect(eventsRecorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          event.eventError == error;
    });
  });
});

context(@"getting bundle of content", ^{
  it(@"should send nil if the product has no content", ^{
    expect([store contentBundleForProduct:productIdentifier]).to.sendValues(@[[NSNull null]]);
  });

  it(@"should send the content bundle from the content fetcher", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    NSBundle *bundle = OCMClassMock([NSBundle class]);
    OCMStub([contentFetcher contentBundleForProduct:OCMOCK_ANY])
        .andReturn([RACSignal return:bundle]);

    LLSignalTestRecorder *recorder =
        [[store contentBundleForProduct:productIdentifier] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[bundle]);
  });
});

context(@"purhcased products", ^{
  it(@"should return empty set if receipt doesn't exist", ^{
    expect([store purchasedProducts]).to.equal([NSSet set]);
  });

  it(@"should return product identifier from in-app purchases", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    expect([store purchasedProducts]).to.equal([NSSet setWithObject:productIdentifier]);
  });
});

context(@"acquired via subscription products", ^{
  it(@"should return acquired via subscription products", ^{
    NSSet *acquiredViaSubscription = [NSSet setWithObject:productIdentifier];
    OCMStub([acquiredViaSubscriptionProvider productsAcquiredViaSubscription])
        .andReturn(acquiredViaSubscription);

    expect(store.acquiredViaSubscriptionProducts).to.equal(acquiredViaSubscription);
  });

  it(@"should add products that marked in the product list as pre acquired", ^{
    BZRProduct *notPreAcquiredProduct = BZRProductWithIdentifier(@"notPreAcquired");
    BZRProduct *preAcquiredProduct = BZRProductWithIdentifier(@"preAcquired");
    preAcquiredProduct = [preAcquiredProduct
        modelByOverridingProperty:@keypath(preAcquiredProduct, preAcquiredViaSubscription)
                        withValue:@YES];

    RACSignal *productList = [RACSignal return:@[notPreAcquiredProduct, preAcquiredProduct]];
    OCMStub([productsProvider fetchProductList]).andReturn(productList);

    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:@"notPreAcquired"]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];
    OCMVerify([acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProduct:@"preAcquired"]);
  });

  it(@"should return empty set if acquired via subscription products is empty", ^{
    NSSet *acquiredViaSubscription = [NSSet set];
    OCMStub([acquiredViaSubscriptionProvider productsAcquiredViaSubscription])
        .andReturn(acquiredViaSubscription);

    expect(store.acquiredViaSubscriptionProducts).to.equal(acquiredViaSubscription);
  });
});

context(@"acquired products", ^{
  it(@"should return in-app purchases unified with acquired via subscription", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    NSSet *acquiredViaSubscription = [NSSet setWithObject:@"bar"];
    OCMStub([acquiredViaSubscriptionProvider productsAcquiredViaSubscription])
        .andReturn(acquiredViaSubscription);

    expect(store.acquiredProducts).to
        .equal([acquiredViaSubscription setByAddingObject:productIdentifier]);
  });
});

context(@"allowed products", ^{
  it(@"should return allowed products provided by allowedProductsProvider", ^{
    NSSet<NSString *> *allowedProducts = [NSSet setWithArray:@[@"foo", @"bar"]];
    allowedProductsProvider.allowedProducts = allowedProducts;

    expect(store.allowedProducts).to.equal(allowedProducts);
  });

  context(@"pre acquired products", ^{
    __block BZRProduct *notPreAcquiredProduct;
    __block BZRProduct *preAcquiredProduct;

    beforeEach(^{
      notPreAcquiredProduct = BZRProductWithIdentifier(@"notPreAcquired");
      preAcquiredProduct = BZRProductWithIdentifier(@"preAcquired");
      preAcquiredProduct =
          [preAcquiredProduct modelByOverridingProperty:@keypath(preAcquiredProduct, preAcquired)
                                              withValue:@YES];

      RACSignal *productList = [RACSignal return:@[notPreAcquiredProduct, preAcquiredProduct]];
      OCMStub([productsProvider fetchProductList]).andReturn(productList);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
    });

    it(@"should include pre acquired products when subscription doesn't exist", ^{
      expect(store.allowedProducts).to.equal([NSSet setWithObject:preAcquiredProduct.identifier]);
    });

    it(@"should include pre acquired products when subscription exists", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRReceiptValidationStatusWithExpiry(NO, NO);
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);

      NSSet *expectedAllowedProducts = [NSSet setWithObject:preAcquiredProduct.identifier];
      expect(store.allowedProducts).to.equal(expectedAllowedProducts);
    });

    it(@"should include pre acquired products when subscription exists and is expired", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRReceiptValidationStatusWithExpiry(YES, NO);
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);

      NSSet *expectedAllowedProducts = [NSSet setWithObject:preAcquiredProduct.identifier];
      expect(store.allowedProducts).to.equal(expectedAllowedProducts);
    });
  });
});

context(@"subscription information", ^{
  it(@"should return subscription from receipt validation status", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    expect(store.subscriptionInfo).to.equal(receiptValidationStatus.receipt.subscription);
  });
});

context(@"fetching nether product list", ^{
  it(@"should prefetch product list on initialization", ^{
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    OCMVerify([netherProductsProvider fetchProductList]);
  });

  it(@"should send a critical error when fetching product list fails", ^{
    auto recorder = [store.eventsSignal testRecorder];

    NSError *error = [NSError lt_errorWithCode:1337];
    [netherProductsProviderSubject sendError:error];

    expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *eventError = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeCriticalError)] &&
          eventError.code == BZRErrorCodeFetchingProductListFailed &&
          eventError.lt_underlyingError == error;
    });
  });
});

context(@"downloaded products", ^{
  beforeEach(^{
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
  });
  it(@"should treat product without content as downloaded", ^{
    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });

  it(@"should filter products without downloaded content", ^{
    BZRStubProductDictionaryToReturnProductWithContent(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet set]);
  });
});

context(@"purchasing products", ^{
  beforeEach(^{
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
  });

  it(@"should send error when product list is empty", ^{
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal empty]);
    expect([store purchaseProduct:productIdentifier]).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  it(@"should send error when product given by variant selector doesn't exist", ^{
    NSArray<BZRProduct *> *productList = @[
      BZRProductWithIdentifier(@"bar"),
      BZRProductWithIdentifier(@"baz")
    ];

    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    expect([store purchaseProduct:@"bar"]).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  it(@"should send non-critical error event when product given by variant selector doesn't "
     "exist", ^{
    LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
    NSArray<BZRProduct *> *productList = @[
      BZRProductWithIdentifier(@"bar"),
      BZRProductWithIdentifier(@"baz")
    ];

    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    [[store purchaseProduct:@"bar"] subscribeNext:^(id) {}];
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventError.lt_isLTDomain &&
          event.eventError.code == BZRErrorCodeInvalidProductForPurchasing &&
          [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
    });
  });

  it(@"should purchase through store kit if product is a renewable subscription", ^{
    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    product = [product modelByOverridingProperty:@keypath(product, productType)
                                       withValue:$(BZRProductTypeRenewableSubscription)];
    BZRStubProductDictionaryToReturnProduct(product, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:productIdentifier]);
    OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    expect([store purchaseProduct:productIdentifier]).will.complete();
  });

  it(@"should purchase through store kit if product is a non renewing subscription", ^{
    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    product = [product modelByOverridingProperty:@keypath(product, productType)
                                       withValue:$(BZRProductTypeNonRenewingSubscription)];
    BZRStubProductDictionaryToReturnProduct(product, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:productIdentifier]);
    OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    expect([store purchaseProduct:productIdentifier]).will.complete();
  });

  it(@"should not add product to acquired via subscription if the subscription doesn't enable the "
     "product", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscriptionProduct");
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    BZRProduct *subscriptionProduct = [BZRProductWithIdentifier(@"subscriptionProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts) withValue:@[]];
    NSArray<BZRProduct *> *productList = @[product, subscriptionProduct];
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    OCMReject([acquiredViaSubscriptionProvider
              addAcquiredViaSubscriptionProduct:productIdentifier]);
    OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);

    expect([store purchaseProduct:productIdentifier]).will.complete();
  });

  it(@"should send error if product is a subscribers only product and user doesn't have a"
     "subscription that enables this product", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscriptionProduct");
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    BZRProduct *product = [BZRProductWithIdentifier(productIdentifier)
        modelByOverridingProperty:@instanceKeypath(BZRProduct, isSubscribersOnly) withValue:@YES];
    BZRProduct *subscriptionProduct = [BZRProductWithIdentifier(@"subscriptionProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts) withValue:@[]];
    NSArray<BZRProduct *> *productList = @[product, subscriptionProduct];
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store purchaseProduct:productIdentifier]).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  context(@"product exists in product list", ^{
    beforeEach(^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
    });

    it(@"should add product to acquired via subscription if subscription exists and not expired", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscription");
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);
      auto productList =
          @[BZRProductWithIdentifier(@"subscription"), BZRProductWithIdentifier(productIdentifier)];
      [netherProductsProviderSubject sendNext:productList];

      expect([store purchaseProduct:productIdentifier]).will.complete();
      OCMVerify([acquiredViaSubscriptionProvider
                 addAcquiredViaSubscriptionProduct:productIdentifier]);
    });

    context(@"purchasing through store kit", ^{
      __block BZRReceiptValidationStatus *receiptValidationStatus;

      beforeEach(^{
        receiptValidationStatus =
            BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, YES);
        OCMStub([receiptValidationStatusProvider receiptValidationStatus])
            .andReturn(receiptValidationStatus);
      });

      it(@"should send non-critical error event when store kit facade fails", ^{
        LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
        NSError *error = [NSError lt_errorWithCode:1337];
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal error:error]);

        [[store purchaseProduct:productIdentifier] subscribeNext:^(id) {}];
        expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
          return event.eventError.lt_isLTDomain && event.eventError == error &&
              [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
        });
      });

      it(@"should send critical error event when receipt validation fails", ^{
        LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
        NSError *error = [NSError lt_errorWithCode:1337];
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal error:error]);

        [[store purchaseProduct:productIdentifier] subscribeNext:^(id) {}];
        expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
          return event.eventError.lt_isLTDomain && event.eventError == error &&
              [event.eventType isEqual:$(BZREventTypeCriticalError)];
        });
      });

      it(@"should not add product to acquired via subscription if subscription is expired", ^{
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        OCMReject([acquiredViaSubscriptionProvider
                   addAcquiredViaSubscriptionProduct:productIdentifier]);
        expect([store purchaseProduct:productIdentifier]).will.complete();
      });

      it(@"should purchase with correct SKProduct", ^{
        SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
        BZRProduct *bazaarProduct = BZRProductWithIdentifier(@"bar");
        bazaarProduct = [bazaarProduct
            modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
                            withValue:underlyingProduct];
        OCMStub([variantSelector selectedVariantForProductWithIdentifier:@"bar"]).andReturn(@"bar");
        BZRStubProductDictionaryToReturnProduct(bazaarProduct, productsProvider);
        BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];

        OCMExpect([storeKitFacade purchaseProduct:underlyingProduct]).andReturn([RACSignal empty]);

        BZRReceiptValidationStatus *receiptValidationWithPurchasedProduct =
            BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"bar", YES);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationWithPurchasedProduct]);

        expect([store purchaseProduct:@"bar"]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
      });

      it(@"should call validate receipt when store kit signal finishes", ^{
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationStatus]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
        OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
      });

      it(@"should not refresh receipt when product is found in receipt after purchasing", ^{
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationStatus]);

        OCMReject([storeKitFacade refreshReceipt]);
        expect([store purchaseProduct:productIdentifier]).will.complete();
      });

      context(@"product not found in receipt after purchasing", ^{
        beforeEach(^{
          BZRProduct *bazaarProduct = BZRProductWithIdentifier(@"bar");
          bazaarProduct = [bazaarProduct
              modelByOverridingProperty:@instanceKeypath(BZRProduct, bzr_underlyingProduct)
              withValue:OCMClassMock([SKProduct class])];
          OCMStub([variantSelector selectedVariantForProductWithIdentifier:@"bar"])
              .andReturn(@"bar");
          BZRStubProductDictionaryToReturnProduct(bazaarProduct, productsProvider);
          store = [[BZRStore alloc] initWithConfiguration:configuration];

          OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        });

        it(@"should refresh receipt when product is not found in receipt after purchasing", ^{
          OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);
          OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);
          OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

          expect([store purchaseProduct:@"bar"]).will.complete();
          OCMVerify([storeKitFacade refreshReceipt]);
        });

        it(@"should send error event when product is not found in receipt after purchasing", ^{
          LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];

          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);

          expect([store purchaseProduct:@"bar"]).will.complete();
          expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
            return event.eventError.lt_isLTDomain &&
                event.eventError.code == BZRErrorCodePurchasedProductNotFoundInReceipt &&
                [event.eventError.bzr_purchasedProductIdentifier isEqualToString:@"bar"] &&
                [event.eventType isEqual:$(BZREventTypeCriticalError)];
          });
        });
      });

      it(@"should call finish transaction when received a transaction with state purchased", ^{
        SKPaymentTransaction *purchasedTransaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([purchasedTransaction transactionState])
            .andReturn(SKPaymentTransactionStatePurchased);
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY])
            .andReturn([RACSignal return:purchasedTransaction]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
        OCMVerify([storeKitFacade finishTransaction:purchasedTransaction]);
      });

      it(@"should not finish transaction when received a transaction with state purchasing", ^{
        SKPaymentTransaction *purchasingTransaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([purchasingTransaction transactionState])
            .andReturn(SKPaymentTransactionStatePurchasing);
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY])
            .andReturn([RACSignal return:purchasingTransaction]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);
        OCMReject([storeKitFacade finishTransaction:OCMOCK_ANY]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
      });

      it(@"should dealloc when all strong references are relinquished", ^{
        BZRStore * __weak weakStore;
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        @autoreleasepool {
          BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier,
                                                                productsProvider);
          BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
          weakStore = store;

          expect([store purchaseProduct:productIdentifier]).will.complete();
        }

        expect(weakStore).to.beNil();
      });
    });
  });
});

context(@"fetching product content", ^{
  it(@"should complete when product has no content", ^{
    LLSignalTestRecorder *recorder = [[store fetchProductContent:productIdentifier] testRecorder];

    expect(recorder).will.sendValues(@[[NSNull null]]);
    expect(recorder).will.complete();
  });

  it(@"should send error when content fetcher errs", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    NSError *error = OCMClassMock([NSError class]);
    OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal error:error]);

    expect([store fetchProductContent:productIdentifier]).will.sendError(error);
  });

  it(@"should send progress sent by content fetcher", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    LTProgress *progress = OCMClassMock([LTProgress class]);
    OCMExpect([contentFetcher fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:productIdentifier];
        }]]).andReturn([RACSignal return:progress]);

    LLSignalTestRecorder *recorder = [[store fetchProductContent:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[progress]);
    OCMVerifyAll((id)contentFetcher);
  });

  it(@"should update downloaded content products", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    LTProgress *progress = OCMClassMock([LTProgress class]);
    OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal return:progress]);

    expect([store fetchProductContent:productIdentifier]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });
});

context(@"deleting product content", ^{
  it(@"should send error when content manager errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([contentManager deleteContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([store deleteProductContent:productIdentifier]).will.sendError(error);
  });

  it(@"should send complete when content manager completes", ^{
    OCMExpect([contentManager deleteContentDirectoryOfProduct:productIdentifier])
        .andReturn([RACSignal empty]);

    expect([store deleteProductContent:productIdentifier]).will.complete();
    OCMVerifyAll((id)contentFetcher);
  });

  it(@"should update downloaded content products", ^{
    BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];

    OCMStub([contentFetcher fetchProductContent:OCMOCK_ANY])
        .andReturn([RACSignal return:[NSBundle bundleWithIdentifier:@"foo"]]);
    expect([store fetchProductContent:productIdentifier]).will.complete();
    expect(store.downloadedContentProducts).will.equal([NSSet setWithObject:productIdentifier]);

    OCMStub([contentManager deleteContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([RACSignal empty]);
    expect([store deleteProductContent:productIdentifier]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet set]);
  });
});

context(@"refreshing receipt", ^{
  context(@"refreshing receipt using store kit facade", ^{
    beforeEach(^{
      OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal empty]);
    });

    it(@"should not err if refresh receipt errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);

      expect([store refreshReceipt]).will.complete();
    });

    it(@"should send error event when refresh receipt errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[store eventsSignal] testRecorder];
      expect([store refreshReceipt]).will.complete();

      expect(recorder).will.sendValues(@[
        [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]
      ]);
    });

    it(@"should validate receipt even if refresh receipt errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);

      expect([store refreshReceipt]).will.complete();

      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });
  });

  context(@"transaction restoration", ^{
    beforeEach(^{
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal empty]);
    });

    it(@"should filter out transaction values", ^{
      OCMStub([storeKitFacade restoreCompletedTransactions])
          .andReturn([RACSignal return:OCMClassMock([SKPaymentTransaction class])]);

      LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).to.sendValuesWithCount(0);
    });

    it(@"should finish restored transactions", ^{
      NSArray<SKPaymentTransaction *> *transactions = @[
        OCMClassMock([SKPaymentTransaction class]),
        OCMClassMock([SKPaymentTransaction class])
      ];
      OCMStub([storeKitFacade restoreCompletedTransactions])
          .andReturn(transactions.rac_sequence.signal);

      OCMExpect([storeKitFacade finishTransaction:transactions[0]]);
      OCMExpect([storeKitFacade finishTransaction:transactions[1]]);

      LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];

      expect(recorder).will.complete();
      OCMVerifyAll((id)storeKitFacade);
    });

    it(@"should not err if transaction restoration errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMExpect([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];

      expect(recorder).will.complete();
    });

    it(@"should send error event when transaction restoration errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[store eventsSignal] testRecorder];
      expect([store refreshReceipt]).will.complete();

      expect(recorder).will.sendValues(@[
        [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError) eventError:error]
      ]);
    });

    it(@"should validate receipt even if transaction restoration errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal error:error]);

      expect([store refreshReceipt]).will.complete();

      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });
  });

  context(@"receipt validation", ^{
    __block BZRReceiptValidationStatus *receiptValidationStatus;

    beforeEach(^{
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
      receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    });

    it(@"should validate the receipt after restoration completed successfully", ^{
      OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([store refreshReceipt]).will.complete();
      OCMVerifyAll((id)receiptValidationStatusProvider);
    });

    it(@"should filter out receipt validation status values", ^{
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);

      LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).to.sendValuesWithCount(0);
    });

    it(@"should err if receipt validation failed", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];

      expect(recorder).will.sendError(error);
    });

    it(@"should send error event when fetch receipt validation status failed", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:error]);

      LLSignalTestRecorder *recorder = [[store eventsSignal] testRecorder];
      expect([store refreshReceipt]).to.finish();

      expect(recorder).will.sendValues(@[
        [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError) eventError:error]
      ]);
    });
  });
});

context(@"getting product list", ^{
  __block BZRProduct *product;

  beforeEach(^{
    product = BZRProductWithIdentifier(productIdentifier);
  });

  it(@"should prefetch product list on initialization", ^{
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];

    OCMVerifyAll((id)productsProvider);
  });

  context(@"products variants", ^{
    beforeEach(^{
      BZRProduct *secondBaseProduct = BZRProductWithIdentifier(@"prod2");
      NSString *firstVariantIdentifier = [productIdentifier stringByAppendingString:@".Variant.A"];
      BZRProduct *firstVariant = BZRProductWithIdentifier(firstVariantIdentifier);
      BZRProduct *secondVariant = BZRProductWithIdentifier(@"prod2.Variant.B");
      RACSignal *productList =
          [RACSignal return:@[product, secondBaseProduct, firstVariant, secondVariant]];
      OCMStub([productsProvider fetchProductList]).andReturn(productList);

      SKProductsResponse *response =
          BZRProductsResponseWithProducts(@[productIdentifier, @"prod2", firstVariantIdentifier,
                                            @"prod2.Variant.B"]);
      NSSet *productSet =
          [NSSet setWithObjects:@"prod2", productIdentifier, firstVariantIdentifier,
           @"prod2.Variant.B", nil];
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:productSet])
          .andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
    });

    it(@"should return variants returned by variant selector", ^{
      OCMExpect([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
          .andReturn([productIdentifier stringByAppendingString:@".Variant.A"]);
      OCMExpect([variantSelector selectedVariantForProductWithIdentifier:@"prod2"])
          .andReturn(@"prod2.Variant.B");

      LLSignalTestRecorder *recorder = [[store productList] testRecorder];

      expect(recorder).to.complete();
      expect(recorder).to.matchValue(0, ^BOOL(NSSet<BZRProduct *> *products) {
        NSSet<NSString *> *productsIdentifiers =
            [products valueForKey:@instanceKeypath(BZRProduct, identifier)];
        return [products count] == 2 &&
            [productsIdentifiers containsObject:productIdentifier] &&
            [productsIdentifiers containsObject:@"prod2"];
      });
      OCMVerifyAll((id)variantSelector);
    });
  });

  it(@"should cache the fetched product list", ^{
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
    BZRStubProductDictionaryToReturnProduct(product, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    OCMReject([productsProvider fetchProductList]);
    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).to.complete();
  });

  it(@"should send error when failed to fetch product list", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:error]);

    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
    BZRStubProductDictionaryToReturnProduct(product, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];
    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.sendError(error);
  });

  it(@"should refetch product list if an error occurred during prefetch", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal error:error]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    BZRStubProductDictionaryToReturnProduct(product, productsProvider);
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSSet setWithObject:product]]);
    OCMVerifyAll((id)productsProvider);
  });

  it(@"should report initial fetching error event via the events signal", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal error:error]);

    auto store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect(store.eventsSignal).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
          [event.eventType isEqual:$(BZREventTypeCriticalError)];
    });
  });

  it(@"should dealloc store whlie product list fetching is in progress.", ^{
    BZRStore * __weak weakStore;
    auto error = [NSError lt_errorWithCode:1337];
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal error:error]);

    auto productListSignal = [RACSubject subject];
    LLSignalTestRecorder *productListRecorder;
    @autoreleasepool {
      auto store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;

      OCMExpect([productsProvider fetchProductList]).andReturn(productListSignal);
      productListRecorder = [[store productList] testRecorder];
    }

    expect(weakStore).to.beNil();
    [productListSignal sendNext:@[product]];
    [productListSignal sendCompleted];
  });

  it(@"should set app store locale from product price locale", ^{
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    SKProduct *underlyingProduct = OCMClassMock([SKProduct class]);
    OCMStub([underlyingProduct priceLocale]).andReturn(locale);
    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    product =
        [product modelByOverridingProperty:@keypath(product, bzr_underlyingProduct)
                                 withValue:underlyingProduct];
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.complete();
    OCMVerify([validationParametersProvider setAppStoreLocale:locale]);
  });
});

context(@"validating receipt", ^{
  it(@"should send error when fetching receipt validation status sends error ", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    expect([store validateReceipt]).to.sendError(error);
  });

  it(@"should complete when fetching receipt validation status completes", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        OCMClassMock([BZRReceiptValidationStatus class]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    LLSignalTestRecorder *recorder = [[store validateReceipt] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[receiptValidationStatus]);
  });
});

context(@"acquiring all enabled products", ^{
  it(@"should send error when user doesn't have an active subscription", ^{
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(BZRReceiptValidationStatusWithExpiry(YES));

    NSError *error = [NSError lt_errorWithCode:BZRErrorCodeAcquireAllRequestedForNonSubscriber];

    expect([store acquireAllEnabledProducts]).to.sendError(error);
  });

  it(@"should add all non subscription products to acquired via subscription", ^{
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscription"));

    BZRProduct *purchasedSubscriptionProduct =
        [BZRProductWithIdentifier(@"subscription")
         modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
         withValue:$(BZRProductTypeRenewableSubscription)];
    BZRProduct *firstProduct = BZRProductWithIdentifier(productIdentifier);
    BZRProduct *secondProduct =
        [BZRProductWithIdentifier(@"bar")
         modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
         withValue:$(BZRProductTypeConsumable)];
    BZRProduct *anotherSubscriptionProduct =
        [BZRProductWithIdentifier(@"baz")
         modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
         withValue:$(BZRProductTypeRenewableSubscription)];
    [netherProductsProviderSubject sendNext:
        @[purchasedSubscriptionProduct, firstProduct, secondProduct, anotherSubscriptionProduct]];

    OCMReject([acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProduct:@"baz"]);

    expect([store acquireAllEnabledProducts]).to.complete();
    OCMVerify([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:productIdentifier]);
    OCMVerify([acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProduct:@"bar"]);
  });

  it(@"should not add products that the subscription doesn't enable to acquired via "
     "subscription", ^{
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscription"));

    BZRProduct *purchasedSubscriptionProduct =
        [[BZRProductWithIdentifier(@"subscription")
         modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
         withValue:$(BZRProductTypeRenewableSubscription)]
         modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
         withValue:@[@"baz"]];
    BZRProduct *notEnabledProduct = BZRProductWithIdentifier(productIdentifier);
    [netherProductsProviderSubject sendNext:@[purchasedSubscriptionProduct, notEnabledProduct]];

    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:productIdentifier]);

    expect([store acquireAllEnabledProducts]).to.complete();
  });
});

context(@"handling unfinished completed transactions", ^{
  __block LLSignalTestRecorder *errorsRecorder;
  __block LLSignalTestRecorder *completedTransactionsRecorder;

  beforeEach(^{
    errorsRecorder = [store.eventsSignal testRecorder];
    completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];

    // Re-initialize store with cahced validation status in order to avoid initial receipt
    // validation due to missing receipt validation status.
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(OCMClassMock([BZRReceiptValidationStatus class]));
    store = [[BZRStore alloc] initWithConfiguration:configuration];
  });

  it(@"should complete when object is deallocated", ^{
    BZRStore * __weak weakStore;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
    }

    expect(weakStore).to.beNil();
    expect(completedTransactionsRecorder).will.complete();
  });

  it(@"should call fetch receipt validation status once for each transactions array", ^{
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray<SKPaymentTransaction *> *transactions = @[transaction, transaction, transaction];
    [unfinishedSuccessfulTransactionsSubject sendNext:transactions];
    [unfinishedSuccessfulTransactionsSubject sendNext:transactions];

    OCMVerifyAllWithDelay((id)receiptValidationStatusProvider, 0.01);
  });

  context(@"purchased transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal empty]);
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    });

    it(@"should finish and fetch receipt validation status", ^{
      [unfinishedSuccessfulTransactionsSubject sendNext:@[transaction]];
      OCMVerify([storeKitFacade finishTransaction:transaction]);
      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });

    it(@"should send transaction on completed transactions signal", ^{
      LLSignalTestRecorder *completedTransactionsRecorder =
          [store.completedTransactionsSignal testRecorder];
      [unfinishedSuccessfulTransactionsSubject sendNext:@[transaction]];
      expect(completedTransactionsRecorder).will.sendValues(@[transaction]);
    });
  });

  context(@"restored transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateRestored);
    });

    it(@"should finish and not fetch receipt validation status", ^{
      [unfinishedSuccessfulTransactionsSubject sendNext:@[transaction]];
      OCMVerify([storeKitFacade finishTransaction:transaction]);
      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });

    it(@"should send transaction on completed transactions signal", ^{
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal empty]);
      LLSignalTestRecorder *completedTransactionsRecorder =
          [store.completedTransactionsSignal testRecorder];
      [unfinishedSuccessfulTransactionsSubject sendNext:@[transaction]];
      expect(completedTransactionsRecorder).will.sendValues(@[transaction]);
    });
  });
});

context(@"events signal", ^{
  __block BZREvent *event;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    NSError *error = [NSError lt_errorWithCode:1337];
    event = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError) eventError:error];
    recorder = [store.eventsSignal testRecorder];
  });

  it(@"should complete when object is deallocated", ^{
    BZRStore * __weak weakStore;
    RACSignal *eventsSignal;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      eventsSignal = store.eventsSignal;
    }

    expect(weakStore).to.beNil();
    expect(eventsSignal).will.complete();
  });

  context(@"errors while fetching product list", ^{
    it(@"should send error event when products provider errs", ^{
      NSError *underlyingError = OCMClassMock([NSError class]);
      OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:underlyingError]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      expect(store.eventsSignal).will.matchValue(0, ^BOOL(BZREvent *event) {
        NSError *error = event.eventError;
        return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
            error.lt_underlyingError == underlyingError;
      });
    });

    it(@"should send event when products provider sends it", ^{
      LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];

      NSError *error = [NSError lt_errorWithCode:1337];
      [productsProviderEventsSubject sendNext:error];

      expect(recorder).will.sendValues(@[error]);
    });
  });

  it(@"should send event sent by receipt validation status provider", ^{
    [receiptValidationStatusProviderEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send event sent by acquired via subscription provider", ^{
    BZREvent *event = OCMClassMock([BZREvent class]);
    [acquiredViaSubscriptionProviderEventsSubject sendNext:event];
    expect(recorder).will.sendValue(0, event);
  });

  it(@"should send event sent by periodic receipt validator activator", ^{
    [periodicReceiptValidatorActivatorEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send error sent by store kit facade", ^{
    NSError *error = OCMClassMock([NSError class]);
    LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
    [transactionsErrorEventsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });
});

context(@"KVO-compliance", ^{
  __block BZRFakeCachedReceiptValidationStatusProvider *validationStatusProvider;
  __block BZRFakeAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
  __block BZRReceiptValidationParametersProvider *validationParametersProvider;

  beforeEach(^{
    validationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
    acquiredViaSubscriptionProvider =  [[BZRFakeAcquiredViaSubscriptionProvider alloc] init];
    validationParametersProvider = [[BZRReceiptValidationParametersProvider alloc] init];

    configuration = OCMClassMock([BZRStoreConfiguration class]);
    OCMStub([configuration productsProvider]).andReturn(productsProvider);
    OCMStub([configuration contentManager]).andReturn(contentManager);
    OCMStub([configuration validationStatusProvider]).andReturn(validationStatusProvider);
    OCMStub([configuration contentFetcher]).andReturn(contentFetcher);
    OCMStub([configuration acquiredViaSubscriptionProvider])
        .andReturn(acquiredViaSubscriptionProvider);
    OCMStub([configuration storeKitFacade]).andReturn(storeKitFacade);
    OCMStub([configuration periodicValidatorActivator]).andReturn(periodicValidatorActivator);
    OCMStub([configuration validationParametersProvider]).andReturn(validationParametersProvider);
    OCMStub([configuration allowedProductsProvider]).andReturn(allowedProductsProvider);
    OCMStub([configuration netherProductsProvider]).andReturn(netherProductsProvider);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
  });

  context(@"purchased products", ^{
    it(@"should update when receipt validation status changes", ^{
      RACSignal *productsSignal = [RACObserve(store, purchasedProducts) testRecorder];
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", NO);

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:@"foo"]
      ]);
    });
  });

  context(@"acquired via subscription products", ^{
    it(@"should update when acquired via subscription list changes", ^{
      RACSignal *productsSignal =
          [RACObserve(store, acquiredViaSubscriptionProducts) testRecorder];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:@"foo"];

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:@"foo"]
      ]);
    });
  });

  context(@"acquired products", ^{
    it(@"should update when acquired via subscription list changes", ^{
      validationStatusProvider.receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
      RACSignal *productsSignal = [RACObserve(store, acquiredProducts) testRecorder];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:@"foo"];

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:@"foo"]
      ]);
    });

    it(@"should update when receipt validation status changes", ^{
      RACSignal *productsSignal = [RACObserve(store, acquiredProducts) testRecorder];
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", NO);

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:@"foo"]
      ]);
    });
  });

  context(@"allowed products", ^{
    it(@"should update when allowed products set is changed", ^{
      LLSignalTestRecorder *productsSignal = [RACObserve(store, allowedProducts) testRecorder];

      allowedProductsProvider.allowedProducts = [NSSet setWithArray:@[@"foo", @"bar"]];

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObjects:@"foo", @"bar", nil]
      ]);
    });

    it(@"should return base product when a variant is found in allowed products", ^{
      allowedProductsProvider.allowedProducts = [NSSet setWithArray:@[@"foo", @"bar.Variant.C"]];

      expect(store.allowedProducts).to.equal([NSSet setWithArray:@[@"foo", @"bar"]]);
    });

    it(@"should update when products dictionary is changed", ^{
      BZRProduct *notPreAcquiredProduct = BZRProductWithIdentifier(@"notPreAcquired");
      BZRProduct *preAcquiredProduct = BZRProductWithIdentifier(@"preAcquired");
      preAcquiredProduct =
          [preAcquiredProduct modelByOverridingProperty:@keypath(preAcquiredProduct, preAcquired)
                                              withValue:@YES];
      NSArray<BZRProduct *> *productList = @[notPreAcquiredProduct, preAcquiredProduct];

      RACSubject *productsProviderSubject = [RACSubject subject];
      OCMStub([productsProvider fetchProductList]).andReturn(productsProviderSubject);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
      RACSignal *productsSignal = [RACObserve(store, allowedProducts) testRecorder];

      [productsProviderSubject sendNext:productList];

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:preAcquiredProduct.identifier]
      ]);
    });
  });

  context(@"subscription info", ^{
    it(@"should update when receipt validation status is changed", ^{
      RACSignal *subscriptionSignal = [RACObserve(store, subscriptionInfo) testRecorder];
      BZRReceiptValidationStatus *activeSubscriptionStatus =
          BZRReceiptValidationStatusWithExpiry(NO);
      BZRReceiptValidationStatus *inactiveSubscriptionStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", YES);
      validationStatusProvider.receiptValidationStatus = activeSubscriptionStatus;
      validationStatusProvider.receiptValidationStatus = inactiveSubscriptionStatus;

      expect(subscriptionSignal).to.sendValues(@[
        [NSNull null],
        activeSubscriptionStatus.receipt.subscription,
        inactiveSubscriptionStatus.receipt.subscription
      ]);
    });
  });

  context(@"receipt validation status", ^{
    it(@"should update when receipt validation status is changed", ^{
      RACSignal *receiptValidationStatusSignal =
          [RACObserve(store, receiptValidationStatus) testRecorder];
      BZRReceiptValidationStatus *activeSubscriptionStatus =
          BZRReceiptValidationStatusWithExpiry(NO);
      BZRReceiptValidationStatus *inactiveSubscriptionStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", YES);
      validationStatusProvider.receiptValidationStatus = activeSubscriptionStatus;
      validationStatusProvider.receiptValidationStatus = inactiveSubscriptionStatus;

      expect(receiptValidationStatusSignal).to.sendValues(@[
        [NSNull null],
        activeSubscriptionStatus,
        inactiveSubscriptionStatus
      ]);
    });
  });

  context(@"receipt validation parameters provider", ^{
    it(@"should update when app store locale changes", ^{
      RACSignal *appStoreLocaleSignal = [RACObserve(store, appStoreLocale) testRecorder];
      NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
      validationParametersProvider.appStoreLocale = locale;

      expect(appStoreLocaleSignal).to.sendValues(@[
        [NSNull null],
        locale
      ]);
    });
  });

  context(@"products JSON dictionary", ^{
    it(@"should be KVO-compliant", ^{
      auto recorder = [RACObserve(store, productsJSONDictionary) testRecorder];

      BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
      [netherProductsProviderSubject sendNext:@[product]];

      expect(recorder).to.sendValues(@[
        [NSNull null],
        @{productIdentifier: product}
      ]);
    });
  });
});

SpecEnd
