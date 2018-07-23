// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedContentFetcher.h"
#import "BZREvent+AdditionalInfo.h"
#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeAggregatedReceiptValidationStatusProvider.h"
#import "BZRFakeAllowedProductsProvider.h"
#import "BZRFakeAppStoreLocaleProvider.h"
#import "BZRKeychainStorage.h"
#import "BZRMultiAppSubscriptionClassifier.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+StoreKit.h"
#import "BZRProductContentManager.h"
#import "BZRProductPriceInfo.h"
#import "BZRProductsProvider.h"
#import "BZRProductsVariantSelector.h"
#import "BZRProductsVariantSelectorFactory.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitCachedMetadataFetcher.h"
#import "BZRStoreKitFacade.h"
#import "BZRTestUtils.h"
#import "BZRUserIDProvider.h"
#import "BZRValidatricksClient.h"
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

static BZRProduct *BZRProductWithPriceInfo(BZRProduct *product, float price,
                                           NSString *localeIdentifier) {
  BZRProductPriceInfo *priceInfo = [BZRProductPriceInfo modelWithDictionary:@{
    @instanceKeypath(BZRProductPriceInfo, price): [NSDecimalNumber numberWithFloat:price],
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier):
        [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier]
  } error:nil];

  return [product modelByOverridingProperty:@keypath(product, priceInfo) withValue:priceInfo];
}

SpecBegin(BZRStore)

__block id<BZRProductsProvider> productsProvider;
__block BZRProductContentManager *contentManager;
__block BZRFakeAggregatedReceiptValidationStatusProvider *
    receiptValidationStatusProvider;
__block BZRCachedContentFetcher *contentFetcher;
__block BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
__block BZRStoreKitFacade *storeKitFacade;
__block BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;
__block id<BZRProductsVariantSelector> variantSelector;
__block BZRFakeAllowedProductsProvider *allowedProductsProvider;
__block id<BZRProductsProvider> netherProductsProvider;
__block BZRStoreKitCachedMetadataFetcher *storeKitMetadataFetcher;
__block BZRFakeAppStoreLocaleProvider *appStoreLocaleProvider;
__block BZRKeychainStorage *keychainStorage;
__block id<BZRValidatricksClient> validatricksClient;
__block id<BZRUserIDProvider> userIDProvider;

__block id<BZRMultiAppSubscriptionClassifier> multiAppSubscriptionClassifier;
__block NSBundle *bundle;
__block RACSubject *productsProviderEventsSubject;
__block RACSubject *receiptValidationStatusProviderEventsSubject;
__block RACSubject *netherProductsProviderSubject;
__block RACSubject *transactionsErrorEventsSubject;
__block RACSubject *contentFetcherEventsSubject;
__block RACSubject *unhandledSuccessfulTransactionsSubject;
__block RACSubject *storeKitMetadataFetcherEventsSubject;
__block RACSubject *keychainStorageEventsSubject;
__block RACSubject *storeKitFacadeEventsSubject;
__block BZRStoreConfiguration *configuration;
__block BZRStore *store;
__block NSString *productIdentifier;

beforeEach(^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  contentManager = OCMClassMock([BZRProductContentManager class]);
  receiptValidationStatusProvider =
      OCMClassMock([BZRFakeAggregatedReceiptValidationStatusProvider class]);
  contentFetcher = OCMClassMock([BZRCachedContentFetcher class]);
  acquiredViaSubscriptionProvider = OCMClassMock([BZRAcquiredViaSubscriptionProvider class]);
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  periodicValidatorActivator = OCMClassMock([BZRPeriodicReceiptValidatorActivator class]);
  variantSelector = OCMProtocolMock(@protocol(BZRProductsVariantSelector));
  allowedProductsProvider = [[BZRFakeAllowedProductsProvider alloc] init];
  netherProductsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  storeKitMetadataFetcher = OCMClassMock([BZRStoreKitCachedMetadataFetcher class]);
  appStoreLocaleProvider = [[BZRFakeAppStoreLocaleProvider alloc] init];
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  validatricksClient = OCMProtocolMock(@protocol(BZRValidatricksClient));
  userIDProvider = OCMProtocolMock(@protocol(BZRUserIDProvider));
  multiAppSubscriptionClassifier = OCMProtocolMock(@protocol(BZRMultiAppSubscriptionClassifier));
  bundle = OCMClassMock([NSBundle class]);
  id<BZRProductsVariantSelectorFactory> variantSelectorFactory =
      OCMProtocolMock(@protocol(BZRProductsVariantSelectorFactory));
  OCMStub([variantSelectorFactory
      productsVariantSelectorWithProductDictionary:OCMOCK_ANY error:[OCMArg anyObjectRef]])
      .andReturn(variantSelector);

  productsProviderEventsSubject = [RACSubject subject];
  receiptValidationStatusProviderEventsSubject = [RACSubject subject];
  netherProductsProviderSubject = [RACSubject subject];
  transactionsErrorEventsSubject = [RACSubject subject];
  contentFetcherEventsSubject = [RACSubject subject];
  unhandledSuccessfulTransactionsSubject = [RACSubject subject];
  storeKitMetadataFetcherEventsSubject = [RACSubject subject];
  keychainStorageEventsSubject = [RACSubject subject];
  storeKitFacadeEventsSubject = [RACSubject subject];

  OCMStub([productsProvider eventsSignal])
      .andReturn(productsProviderEventsSubject);
  OCMStub([receiptValidationStatusProvider eventsSignal])
      .andReturn(receiptValidationStatusProviderEventsSubject);
  OCMStub([netherProductsProvider fetchProductList]).andReturn(netherProductsProviderSubject);
  OCMStub([storeKitFacade transactionsErrorEventsSignal])
      .andReturn(transactionsErrorEventsSubject);
  OCMStub([contentFetcher eventsSignal]).andReturn(contentFetcherEventsSubject);
  OCMStub([storeKitFacade unhandledSuccessfulTransactionsSignal])
      .andReturn(unhandledSuccessfulTransactionsSubject);
  OCMStub([storeKitMetadataFetcher eventsSignal]).andReturn(storeKitMetadataFetcherEventsSubject);
  OCMStub([keychainStorage eventsSignal]).andReturn(keychainStorageEventsSubject);
  OCMStub([storeKitFacade eventsSignal]).andReturn(storeKitFacadeEventsSubject);

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
  OCMStub([configuration allowedProductsProvider]).andReturn(allowedProductsProvider);
  OCMStub([configuration netherProductsProvider]).andReturn(netherProductsProvider);
  OCMStub([configuration storeKitMetadataFetcher]).andReturn(storeKitMetadataFetcher);
  OCMStub([configuration appStoreLocaleProvider]).andReturn(appStoreLocaleProvider);
  OCMStub([configuration keychainStorage]).andReturn(keychainStorage);
  OCMStub([configuration validatricksClient]).andReturn(validatricksClient);
  OCMStub([configuration userIDProvider]).andReturn(userIDProvider);

  store = [[BZRStore alloc] initWithConfiguration:configuration];
  productIdentifier = @"foo";
});

context(@"initial receipt validation", ^{
  it(@"should fetch receipt on initialization if receipt validation status is nil and App Store "
     "locale was fetched", ^{
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];

    OCMVerifyAll((id)receiptValidationStatusProvider);
  });

  it(@"should not fetch receipt on initialization if receipt validation status is nil and App "
     "Store locale was not fetched", ^{
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
  });

  it(@"should not fetch receipt on initialization if receipt validation status is not nil and "
     "App Store locale was fetched", ^{
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(OCMClassMock([BZRReceiptValidationStatus class]));

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
  });

  it(@"should send error event if background receipt validation failed", ^{
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    LLSignalTestRecorder *eventsRecorder = [[store eventsSignal] testRecorder];
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];

    expect(eventsRecorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeCriticalError)] && event.eventError == error;
    });
  });
});

context(@"multi-app subscription", ^{
  beforeEach(^{
    OCMStub([multiAppSubscriptionClassifier
             isMultiAppSubscription:[OCMArg checkWithBlock:^BOOL(NSString *productId) {
      return [productId containsString:@"MultiApp"];
    }]]).andReturn(YES);
  });

  it(@"should return YES if ths product identifier contains the multi-app subscription marker", ^{
    OCMStub([configuration multiAppSubscriptionClassifier])
        .andReturn(multiAppSubscriptionClassifier);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    auto subscriptionIdentifier = @"com.bundleID.MultiApp.foo";

    expect([store isMultiAppSubscription:subscriptionIdentifier]).to.beTruthy();
  });

  it(@"should return NO if the product identifier doesn't contain the multi-app subscription "
     "marker", ^{
    OCMStub([configuration multiAppSubscriptionClassifier])
        .andReturn(multiAppSubscriptionClassifier);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store isMultiAppSubscription:@"com.bundleID.foo"]).to.beFalsy();
  });

  it(@"should return NO if the multi-app subscription marker is nil", ^{
    auto subscriptionIdentifier = @"com.bundleID.MultiAppMarker.foo";

    expect([store isMultiAppSubscription:subscriptionIdentifier]).to.beFalsy();
  });
});

context(@"App Store locale", ^{
  it(@"should not send event with the first app store locale value", ^{
    LLSignalTestRecorder *eventsRecorder;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      eventsRecorder = [store.eventsSignal testRecorder];
    }

    expect(eventsRecorder).will.complete();
    expect(eventsRecorder).will.sendValuesWithCount(0);
  });

  it(@"should send event for every app store locale change", ^{
    auto eventsRecorder = [store.eventsSignal testRecorder];

    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    appStoreLocaleProvider.appStoreLocale = nil;

    expect(eventsRecorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeInformational)] &&
          [event.eventInfo[BZREventAppStoreLocaleKey]
           isEqual:[NSLocale currentLocale].localeIdentifier];
    });
    expect(eventsRecorder).to.matchValue(1, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeInformational)] &&
          [event.eventInfo[BZREventAppStoreLocaleKey] isEqual:[NSNull null]];
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
        addAcquiredViaSubscriptionProducts:[OCMArg checkWithBlock:^BOOL(NSSet *identifiers) {
          return [identifiers containsObject:@"notPreAcquired"];
        }]]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];
    OCMVerify([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProducts:[NSSet setWithObject:@"preAcquired"]]);
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
  __block SKProduct *underlyingProduct;
  __block NSString *productIdentifier;
  __block BZRProduct *product;
  __block NSString *subscriptionIdentifier;
  __block BZRProduct *subscriptionProduct;
  __block BZRProduct *nonRenewingSubscriptionProduct;

  beforeEach(^{
    underlyingProduct = OCMClassMock([SKProduct class]);

    productIdentifier = @"product";
    product = [BZRProductWithIdentifier(productIdentifier)
        modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
        withValue:underlyingProduct];

    subscriptionIdentifier = @"susbscription";
    subscriptionProduct = [[BZRProductWithIdentifier(subscriptionIdentifier)
        modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
        withValue:$(BZRProductTypeRenewableSubscription)]
        modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
        withValue:underlyingProduct];

    nonRenewingSubscriptionProduct = [[BZRProductWithIdentifier(subscriptionIdentifier)
        modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
        withValue:$(BZRProductTypeNonRenewingSubscription)]
        modelByOverridingProperty:@instanceKeypath(BZRProduct, underlyingProduct)
        withValue:underlyingProduct];

    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:subscriptionIdentifier])
        .andReturn(subscriptionIdentifier);
  });

  it(@"should err when product list is empty", ^{
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[]]);

    auto purchaseSignal = [store purchaseProduct:productIdentifier];

    expect(purchaseSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  it(@"should err when product given by variant selector doesn't exist", ^{
    OCMStub([productsProvider fetchProductList]).andReturn(([RACSignal return:@[
      BZRProductWithIdentifier(@"bar"),
      BZRProductWithIdentifier(@"baz")
    ]]));

    auto purchaseSignal = [store purchaseProduct:productIdentifier];

    expect(purchaseSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  it(@"should send error event when product given by variant selector doesn't exist", ^{
    auto eventsRecorder = [store.eventsSignal testRecorder];
    OCMStub([productsProvider fetchProductList]).andReturn(([RACSignal return:@[
      BZRProductWithIdentifier(@"bar"),
      BZRProductWithIdentifier(@"baz")
    ]]));

    auto purchaseRecorder = [[store purchaseProduct:productIdentifier] testRecorder];

    expect(purchaseRecorder).will.finish();
    expect(eventsRecorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventError.lt_isLTDomain &&
          event.eventError.code == BZRErrorCodeInvalidProductForPurchasing &&
          [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
    });
  });

  it(@"should purchase through StoreKit if product is a renewable subscription", ^{
    auto receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(subscriptionIdentifier);
    BZRStubProductDictionaryToReturnProduct(subscriptionProduct, productsProvider);

    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:subscriptionIdentifier]);
    OCMExpect([storeKitFacade purchaseProduct:underlyingProduct quantity:1])
        .andReturn([RACSignal empty]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    [netherProductsProviderSubject sendNext:@[subscriptionProduct]];
    auto purchaseSignal = [store purchaseProduct:subscriptionIdentifier];

    expect(purchaseSignal).will.complete();
    OCMVerifyAll((id)storeKitFacade);
  });

  it(@"should purchase through StoreKit if product is a non-renewing subscription", ^{
    auto receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(subscriptionIdentifier);
    BZRStubProductDictionaryToReturnProduct(nonRenewingSubscriptionProduct, productsProvider);

    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    OCMReject([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:subscriptionIdentifier]);
    OCMExpect([storeKitFacade purchaseProduct:underlyingProduct quantity:1])
        .andReturn([RACSignal empty]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    [netherProductsProviderSubject sendNext:@[subscriptionProduct]];
    auto purchaseSignal = [store purchaseProduct:subscriptionIdentifier];

    expect(purchaseSignal).will.complete();
    OCMVerifyAll((id)storeKitFacade);
  });

  it(@"should not add product to acquired via subscription products if the subscription doesn't "
      "enable the product", ^{
    subscriptionProduct = [subscriptionProduct
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts) withValue:@[]];
    auto receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(subscriptionIdentifier);
    auto productList = @[product, subscriptionProduct];

    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    OCMStub([storeKitFacade purchaseProduct:underlyingProduct quantity:1])
        .andReturn([RACSignal empty]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    OCMReject([acquiredViaSubscriptionProvider addAcquiredViaSubscriptionProduct:OCMOCK_ANY]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    [netherProductsProviderSubject sendNext:productList];
    auto purchaseSignal = [store purchaseProduct:productIdentifier];

    expect(purchaseSignal).will.complete();
  });

  it(@"should add product to acquired via subscription products if the active subscription doesn't "
      "exist in the product list", ^{
    auto receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(subscriptionIdentifier);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    OCMReject([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1]);
    OCMExpect([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProduct:productIdentifier]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    [netherProductsProviderSubject sendNext:@[product]];
    auto purchaseSignal = [store purchaseProduct:productIdentifier];

    expect(purchaseSignal).will.complete();
    OCMVerifyAll((id)acquiredViaSubscriptionProvider);
  });

  it(@"should send error if product is a subscribers only product and user doesn't have a"
     "subscription that enables this product", ^{
    auto subscriptionProduct = [BZRProductWithIdentifier(@"subscriptionProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, enablesProducts)
        withValue:@[@"allowedProduct"]];
    auto product = [BZRProductWithIdentifier(@"notAllowedProduct")
        modelByOverridingProperty:@instanceKeypath(BZRProduct, isSubscribersOnly) withValue:@YES];
    auto receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscriptionProduct");
    NSArray<BZRProduct *> *productList = @[product, subscriptionProduct];
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    [netherProductsProviderSubject sendNext:productList];
    auto purchaseSignal = [store purchaseProduct:productIdentifier];

    expect(purchaseSignal).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductForPurchasing;
    });
  });

  context(@"product exists in product list", ^{
    beforeEach(^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
    });

    it(@"should add product to acquired via subscription if subscription exists and not expired", ^{
      auto receiptValidationStatus =
          BZRReceiptValidationStatusWithSubscriptionIdentifier(@"subscription");
      auto subscriptionProduct = [BZRProductWithIdentifier(@"subscription")
          modelByOverridingProperty:@instanceKeypath(BZRProduct, productType)
          withValue:$(BZRProductTypeRenewableSubscription)];
      auto productList = @[subscriptionProduct, BZRProductWithIdentifier(productIdentifier)];
      [netherProductsProviderSubject sendNext:productList];

      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);

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

        BZRStubProductDictionaryToReturnProduct(product, productsProvider);
        store = [[BZRStore alloc] initWithConfiguration:configuration];
      });

      it(@"should send non-critical error event when store kit facade fails", ^{
        LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
        NSError *error = [NSError lt_errorWithCode:1337];
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
            .andReturn([RACSignal error:error]);

        expect([store purchaseProduct:productIdentifier]).will.finish();
        expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
          return event.eventError.lt_isLTDomain && event.eventError == error &&
              [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
        });
      });

      it(@"should send critical error event when receipt validation fails", ^{
        LLSignalTestRecorder *recorder = [store.eventsSignal testRecorder];
        NSError *error = [NSError lt_errorWithCode:1337];
        SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
            .andReturn([RACSignal return:transaction]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal error:error]);

        expect([store purchaseProduct:productIdentifier]).will.finish();
        expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
          return event.eventError.lt_isLTDomain && event.eventError == error &&
              [event.eventType isEqual:$(BZREventTypeCriticalError)];
        });
      });

      it(@"should not add product to acquired via subscription if subscription is expired", ^{
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
            .andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        OCMReject([acquiredViaSubscriptionProvider
                   addAcquiredViaSubscriptionProduct:productIdentifier]);
        expect([store purchaseProduct:productIdentifier]).will.complete();
      });

      it(@"should purchase with correct SKProduct", ^{
        OCMExpect([storeKitFacade purchaseProduct:underlyingProduct quantity:1])
            .andReturn([RACSignal empty]);

        BZRReceiptValidationStatus *receiptValidationWithPurchasedProduct =
            BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, YES);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationWithPurchasedProduct]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
      });

      context(@"purchase consumable product", ^{
        it(@"should purchase with the correct quantity", ^{
         OCMExpect([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:3])
            .andReturn([RACSignal empty]);
         OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationStatus]);

         expect([store purchaseConsumableProduct:productIdentifier quantity:3]).will.complete();
         OCMVerifyAll((id)storeKitFacade);
        });

        it(@"should send an error if the purchase quantity is invalid", ^{
          auto recorder =
              [[store purchaseConsumableProduct:productIdentifier quantity:11] testRecorder];

          expect(recorder).to.matchError(^BOOL(NSError *error) {
            return error.code == BZRErrorCodeInvalidQuantityForPurchasing;
          });
        });

        it(@"should send an error if the underlying StoreKit product was not found", ^{
          expect([store purchaseConsumableProduct:@"bar" quantity:1])
              .matchError(^BOOL(NSError *error) {
                return error.code == BZRErrorCodeInvalidProductForPurchasing;
              });
        });
      });

      context(@"validating receipt and finishing transactions", ^{
        __block SKPaymentTransaction *purchasedTransaction;

        beforeEach(^{
          purchasedTransaction = OCMClassMock([SKPaymentTransaction class]);
          OCMStub([purchasedTransaction transactionState])
              .andReturn(SKPaymentTransactionStatePurchased);
          OCMStub([purchasedTransaction transactionIdentifier]).andReturn(@"foo");
          OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
              .andReturn([RACSignal return:purchasedTransaction]);
        });

        it(@"should validate receipt when store kit signal sends a transaction", ^{
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);
          expect([store purchaseProduct:productIdentifier]).will.finish();
          OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
        });

        it(@"should send error when validation fails", ^{
          auto validationError = [NSError lt_errorWithCode:1337];
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal error:validationError]);

          expect([store purchaseProduct:productIdentifier]).will.matchError(^BOOL(NSError *error) {
            return error.code == BZRErrorCodePurchaseFailed &&
                error.lt_underlyingError == validationError;
          });
        });

        it(@"should send two error events when validation fails", ^{
          auto recorder = [store.eventsSignal testRecorder];
          auto validationError = [NSError lt_errorWithCode:1337];
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal error:validationError]);

          expect([store purchaseProduct:productIdentifier]).will.finish();
          expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
            auto error = event.eventError;
            return [event.eventType isEqual:$(BZREventTypeCriticalError)] &&
                error == validationError;
          });
          expect(recorder).will.matchValue(1, ^BOOL(BZREvent *event) {
            auto error = event.eventError;
            return [event.eventType isEqual:$(BZREventTypeCriticalError)] &&
                error.code == BZRErrorCodePurchaseFailed &&
                error.lt_underlyingError == validationError;
          });
        });

        it(@"should finish product's transaction if it appears in receipt transactions", ^{
          receiptValidationStatus = [receiptValidationStatus modelByOverridingPropertyAtKeypath:
              @keypath(receiptValidationStatus, receipt.transactions)
              withValue:@[BZRTransactionWithTransactionIdentifier(@"foo")]];
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);

          expect([store purchaseProduct:productIdentifier]).will.complete();

          OCMVerify([storeKitFacade finishTransaction:purchasedTransaction]);
        });

        it(@"should finish product's transaction if its date appears in receipt transactions", ^{
          receiptValidationStatus = [receiptValidationStatus modelByOverridingPropertyAtKeypath:
              @keypath(receiptValidationStatus, receipt.transactions)
              withValue:@[BZRTransactionWithTransactionIdentifier(@"notFoo")]];
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);
          OCMStub([purchasedTransaction transactionDate])
              .andReturn(receiptValidationStatus.receipt.transactions.firstObject.purchaseDateTime);

          expect([store purchaseProduct:productIdentifier]).will.complete();

          OCMVerify([storeKitFacade finishTransaction:purchasedTransaction]);
        });

        it(@"should not finish product's transaction if it doesn't appear in receipt "
           "transactions", ^{
          OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
              .andReturn([RACSignal return:receiptValidationStatus]);
          OCMReject([storeKitFacade finishTransaction:OCMOCK_ANY]);

          expect([store purchaseProduct:productIdentifier]).will.finish();
        });
      });

      it(@"should not finish transaction when received a transaction with state purchasing", ^{
        SKPaymentTransaction *purchasingTransaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([purchasingTransaction transactionState])
            .andReturn(SKPaymentTransactionStatePurchasing);
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
            .andReturn([RACSignal return:purchasingTransaction]);
        receiptValidationStatus = [receiptValidationStatus modelByOverridingPropertyAtKeypath:
            @keypath(receiptValidationStatus, receipt.transactions)
            withValue:@[BZRTransactionWithTransactionIdentifier(@"foo")]];
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal return:receiptValidationStatus]);
        OCMReject([storeKitFacade finishTransaction:OCMOCK_ANY]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
      });

      it(@"should dealloc when all strong references are relinquished", ^{
        BZRStore * __weak weakStore;
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY quantity:1])
            .andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        @autoreleasepool {
          BZRStubProductDictionaryToReturnProduct(product, productsProvider);
          BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
          weakStore = store;

          expect([store purchaseProduct:productIdentifier]).will.complete();
        }

        expect(weakStore).to.beNil();
      });
    });
  });
});

context(@"validating transaction", ^{
  __block SKPaymentTransaction *transaction;

  beforeEach(^{
    transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionIdentifier]).andReturn(@"foo");
  });

  it(@"should err if transaction identifier wasn't found in transactions array", ^{
    OCMStub([storeKitFacade transactions]).andReturn(@[]);

    expect([store validateTransaction:@"foo"]).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeInvalidTransactionIdentifier;
    });
  });

  it(@"should err if transaction in transactions array is not in state purchased", ^{
    OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);

    expect([store validateTransaction:@"foo"]).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeInvalidTransactionIdentifier;
    });
  });

  context(@"transaction is valid", ^{
    beforeEach(^{
      OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    });

    it(@"should not validate receipt if refresh receipt erred with cancellation", ^{
      auto error = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);
      OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

      expect([store validateTransaction:@"foo"]).will.sendError(error);
    });

    it(@"should validate the receipt if the refresh receipt erred", ^{
      OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(YES)]);

      expect([store validateTransaction:@"foo"]).will.finish();
      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });

    it(@"should err if validation failed", ^{
      OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:error]);

      expect([store validateTransaction:@"foo"]).will.sendError(error);
    });

    it(@"should err if transaction is not found in receipt after validation", ^{
      OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(YES)]);

      auto recorder = [store validateTransaction:@"foo"];
      expect(recorder).will.matchError(^BOOL(NSError *error) {
        return error.code == BZRErrorCodeTransactionNotFoundInReceipt &&
            error.bzr_transaction == transaction;
      });
    });

    it(@"should complete if transaction is found in receipt after validation", ^{
      OCMStub([storeKitFacade transactions]).andReturn(@[transaction]);
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
      receiptValidationStatus = [receiptValidationStatus
          modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, receipt.transactions)
                                   withValue:@[BZRTransactionWithTransactionIdentifier(@"foo")]];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([store validateTransaction:@"foo"]).will.complete();
    });
  });
});

context(@"getting user credit status", ^{
  __block BZRUserCreditStatus *userCreditStatus;
  __block BZRReceiptValidationStatus *receiptValidationStatus;

  beforeEach(^{
    userCreditStatus = lt::nn([[BZRUserCreditStatus alloc] initWithDictionary:@{
      @instanceKeypath(BZRUserCreditStatus, requestId): @"request",
      @instanceKeypath(BZRUserCreditStatus, creditType): @"bar",
      @instanceKeypath(BZRUserCreditStatus, credit): @13,
      @instanceKeypath(BZRUserCreditStatus, consumedItems): @[]
    } error:nil]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
  });

  context(@"receipt validation status exists", ^{
    beforeEach(^{
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);
    });

    it(@"should forward request to Validatricks client with correct parameters", ^{
      OCMStub([validatricksClient getCreditOfType:@"bar" forUser:@"foo"
          environment:receiptValidationStatus.receipt.environment])
          .andReturn([RACSignal return:userCreditStatus]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");

      auto recorder = [[store getUserCreditStatus:@"bar"] testRecorder];

      expect(recorder).to.complete();
      expect(recorder).to.sendValues(@[userCreditStatus]);
    });

    it(@"should not access user ID before subscription to the signal", ^{
      OCMStub([validatricksClient getCreditOfType:OCMOCK_ANY forUser:OCMOCK_ANY
          environment:OCMOCK_ANY])
          .andReturn([RACSignal empty]);

      auto signal = [store getUserCreditStatus:@"bar"];

      OCMExpect([userIDProvider userID]).andReturn(@"foo");
      expect(signal).to.complete();

      OCMExpect([userIDProvider userID]).andReturn(@"bar");
      expect(signal).to.complete();

      OCMVerifyAll((id)userIDProvider);
    });

    it(@"should send error sent by Validatricks client", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([validatricksClient getCreditOfType:@"bar" forUser:@"foo" environment:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");

      auto signal = [store getUserCreditStatus:@"bar"];

      expect(signal).to.sendError(error);
    });

    it(@"should send error if user ID is nil", ^{
      OCMReject([validatricksClient getCreditOfType:OCMOCK_ANY forUser:OCMOCK_ANY
                                        environment:OCMOCK_ANY]);

      auto signal = [store getUserCreditStatus:@"bar"];

      expect(signal).to.matchError(^BOOL(NSError *error) {
        return error.code == BZRErrorCodeUserIdentifierNotAvailable;
      });
    });

    it(@"should cache the user credit after successful fetching", ^{
      OCMStub([validatricksClient getCreditOfType:@"bar" forUser:@"foo" environment:OCMOCK_ANY])
          .andReturn([RACSignal return:userCreditStatus]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");
      OCMExpect([keychainStorage setValue:userCreditStatus forKey:@"bzr.userCredit.bar" error:nil]);

      auto signal = [store getUserCreditStatus:@"bar"];

      expect(signal).will.complete();
      OCMVerifyAll((id)keychainStorage);
    });
  });

  context(@"receipt validation status doesn't exist", ^{
    beforeEach(^{
      OCMStub([validatricksClient getCreditOfType:@"bar" forUser:@"foo" environment:OCMOCK_ANY])
          .andReturn([RACSignal return:userCreditStatus]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");
    });

    it(@"should validate receipt if receipt validation status doesn't exist", ^{
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([store getUserCreditStatus:@"bar"]).will.complete();

      OCMVerifyAll((id)receiptValidationStatusProvider);
    });

    it(@"should send error if receipt validation failed", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:error]);

      expect([store getUserCreditStatus:@"bar"]).will.sendError(error);
    });
  });
});

context(@"cached user credit", ^{
  it(@"should get the cached user credit", ^{
    auto userCreditStatus = lt::nn([[BZRUserCreditStatus alloc] initWithDictionary:@{
      @instanceKeypath(BZRUserCreditStatus, requestId): @"request",
      @instanceKeypath(BZRUserCreditStatus, creditType): @"bar",
      @instanceKeypath(BZRUserCreditStatus, credit): @13,
      @instanceKeypath(BZRUserCreditStatus, consumedItems): @[]
    } error:nil]);

    OCMStub([keychainStorage valueForKey:@"bzr.userCredit.bar" error:nil])
        .andReturn(userCreditStatus);

    expect([store getCachedUserCreditStatus:@"bar"]).to.equal(userCreditStatus);
  });

  it(@"should return nil if the user credit was not found in cache", ^{
    expect([store getCachedUserCreditStatus:@"bar"]).to.beNil();
  });
});

context(@"getting credit price for consumable types", ^{
  it(@"should forward request to Validatricks client with correct parameters", ^{
    auto consumableTypes = @[@"fooType", @"barType"].lt_set;
    auto creditType = @"baz";
    auto consumableTypeToPrice = @{
      @"fooType": @1,
      @"barType": @3
    };
    auto typesPriceInfo = lt::nn([[BZRConsumableTypesPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRConsumableTypesPriceInfo, requestId): @"requestId",
      @instanceKeypath(BZRConsumableTypesPriceInfo, creditType): creditType,
      @instanceKeypath(BZRConsumableTypesPriceInfo, consumableTypesPrices): consumableTypeToPrice
    } error:nil]);

    OCMStub([validatricksClient getPricesInCreditType:creditType
                                   forConsumableTypes:consumableTypes.allObjects])
        .andReturn([RACSignal return:typesPriceInfo]);

    auto recorder = [[store getCreditPriceOfType:creditType
                                 consumableTypes:consumableTypes] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[consumableTypeToPrice]);
  });

  it(@"should send error sent by Validatricks client", ^{
    auto consumableTypes = @[@"fooType", @"barType"].lt_set;
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([validatricksClient getPricesInCreditType:OCMOCK_ANY forConsumableTypes:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);
    OCMStub([userIDProvider userID]).andReturn(@"foo");

    auto signal = [store getCreditPriceOfType:@"foo" consumableTypes:consumableTypes];

    expect(signal).to.sendError(error);
  });

  it(@"should send error if price of one of the elements in consumable types wasn't fetched", ^{
    auto consumableTypes = @[@"fooType", @"barType"].lt_set;
    auto creditType = @"baz";
    auto consumableTypeToPrice = @{@"fooType": @1};
    auto typesPriceInfo = lt::nn([[BZRConsumableTypesPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRConsumableTypesPriceInfo, requestId): @"requestId",
      @instanceKeypath(BZRConsumableTypesPriceInfo, creditType): creditType,
      @instanceKeypath(BZRConsumableTypesPriceInfo, consumableTypesPrices): consumableTypeToPrice
    } error:nil]);

    OCMStub([validatricksClient getPricesInCreditType:creditType
                                   forConsumableTypes:consumableTypes.allObjects])
        .andReturn([RACSignal return:typesPriceInfo]);

    auto signal = [store getCreditPriceOfType:creditType consumableTypes:consumableTypes];

    expect(signal).to.matchError(^BOOL(NSError *error){
      return error.code == BZRErrorCodeValidatricksRequestFailed;
    });
  });
});

context(@"redeeming consumable items", ^{
  __block BZRReceiptValidationStatus *receiptValidationStatus;
  __block NSDictionary<NSString *, NSString *> *consumableItemIDToType;

  beforeEach(^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    consumableItemIDToType = @{
      @"foo": @"fooType",
      @"bar": @"barType"
    };
  });

  context(@"receipt validation status exists", ^{
    beforeEach(^{
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);
      });

    it(@"should call Validatricks redeem request with correct parameters", ^{
      auto creditType = @"baz";
      OCMStub([userIDProvider userID]).andReturn(@"foo");

      auto itemsToRedeem = @[
        lt::nn([[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
          @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): @"foo",
          @instanceKeypath(BZRConsumableItemDescriptor, consumableType): @"fooType",
        } error:nil]),
        lt::nn([[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
          @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): @"bar",
          @instanceKeypath(BZRConsumableItemDescriptor, consumableType): @"barType",
        } error:nil])
      ];
      auto redeemStatus = lt::nn([[BZRRedeemConsumablesStatus alloc] initWithDictionary:@{
        @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
        @instanceKeypath(BZRRedeemConsumablesStatus, creditType): creditType,
        @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @13,
        @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @[]
      } error:nil]);
      OCMStub([validatricksClient redeemConsumableItems:itemsToRedeem ofCreditType:creditType
          userId:@"foo" environment:receiptValidationStatus.receipt.environment])
          .andReturn([RACSignal return:redeemStatus]);

      auto recorder = [[store redeemConsumableItems:consumableItemIDToType
                                       ofCreditType:creditType] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[redeemStatus]);
    });

    it(@"should not access user ID before subscription to the signal", ^{
      OCMStub([validatricksClient redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY
                                                 userId:OCMOCK_ANY environment:OCMOCK_ANY])
          .andReturn([RACSignal empty]);

      auto signal = [store redeemConsumableItems:consumableItemIDToType ofCreditType:@"foo"];

      OCMExpect([userIDProvider userID]).andReturn(@"foo");
      expect(signal).to.complete();

      OCMExpect([userIDProvider userID]).andReturn(@"bar");
      expect(signal).to.complete();

      OCMVerifyAll((id)userIDProvider);
    });

    it(@"should send error sent by Validatricks client", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([validatricksClient redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY
                                                 userId:OCMOCK_ANY environment:OCMOCK_ANY])
          .andReturn([RACSignal error:error]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");

      auto signal = [store redeemConsumableItems:consumableItemIDToType ofCreditType:@"baz"];

      expect(signal).to.sendError(error);
    });

    it(@"should send error if user ID is nil", ^{
      OCMReject([validatricksClient redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY
                                                   userId:OCMOCK_ANY environment:OCMOCK_ANY]);

      auto signal = [store redeemConsumableItems:consumableItemIDToType ofCreditType:@"baz"];

      expect(signal).to.matchError(^BOOL(NSError *error) {
        return error.code == BZRErrorCodeUserIdentifierNotAvailable;
      });
    });
  });

  context(@"receipt validation status doesn't exist", ^{
    beforeEach(^{
      auto redeemStatus = lt::nn([[BZRRedeemConsumablesStatus alloc] initWithDictionary:@{
        @instanceKeypath(BZRRedeemConsumablesStatus, requestId): @"requestId",
        @instanceKeypath(BZRRedeemConsumablesStatus, creditType): @"bar",
        @instanceKeypath(BZRRedeemConsumablesStatus, currentCredit): @13,
        @instanceKeypath(BZRRedeemConsumablesStatus, consumedItems): @[]
      } error:nil]);
      OCMStub([validatricksClient redeemConsumableItems:OCMOCK_ANY ofCreditType:OCMOCK_ANY
                                                 userId:OCMOCK_ANY environment:OCMOCK_ANY])
          .andReturn([RACSignal return:redeemStatus]);
      OCMStub([userIDProvider userID]).andReturn(@"foo");
    });

    it(@"should validate receipt if receipt validation status doesn't exist", ^{
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);

      expect([store redeemConsumableItems:consumableItemIDToType ofCreditType:@"bar"])
          .will.complete();

      OCMVerifyAll((id)receiptValidationStatusProvider);
    });

    it(@"should send error if receipt validation failed", ^{
      auto error = [NSError lt_errorWithCode:1337];
      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:error]);

      expect([store redeemConsumableItems:consumableItemIDToType ofCreditType:@"bar"])
          .will.sendError(error);
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

    it(@"should not validate receipt when refresh receipt erred with cancellation", ^{
      NSError *receiptRefreshError = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:receiptRefreshError]);
      OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

      expect([store refreshReceipt]).will.matchError(^BOOL(NSError *error) {
        return receiptRefreshError == error;
      });
    });

    it(@"should not restore completed transactions when refresh receipt erred with cancellation", ^{
      NSError *receiptRefreshError = [NSError lt_errorWithCode:BZRErrorCodeOperationCancelled];
      OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:receiptRefreshError]);
      OCMReject([storeKitFacade restoreCompletedTransactions]);

      expect([store refreshReceipt]).will.matchError(^BOOL(NSError *error) {
        return receiptRefreshError == error;
      });
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

    OCMReject([acquiredViaSubscriptionProvider
        addAcquiredViaSubscriptionProducts:[OCMArg checkWithBlock:^BOOL(NSSet *identifiers) {
          return [identifiers containsObject:@"baz"];
        }]]);

    expect([store acquireAllEnabledProducts]).to.complete();
    auto nonSubscriptionProducts = [NSSet setWithArray:@[productIdentifier, @"bar"]];
    OCMVerify([acquiredViaSubscriptionProvider
               addAcquiredViaSubscriptionProducts:nonSubscriptionProducts]);
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
        addAcquiredViaSubscriptionProducts:[OCMArg checkWithBlock:^BOOL(NSSet *identifiers) {
          return [identifiers containsObject:productIdentifier];
        }]]);

    expect([store acquireAllEnabledProducts]).to.complete();
  });
});

context(@"manually fetching products info", ^{
  it(@"should err if products info fetcher errs", ^{
    auto product = BZRProductWithIdentifier(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product, BZRProductWithIdentifier(@"bar")]];
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([store fetchProductsInfo:@[productIdentifier].lt_set]).will.sendError(error);
  });

  it(@"should send error in case a requested product doesn't appear in product list provided by "
     "nether products provider", ^{
    auto product = BZRProductWithIdentifier(productIdentifier);
    [netherProductsProviderSubject sendNext:@[product]];
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[]]).andReturn([RACSignal return:@[]]);

    expect([store fetchProductsInfo:@[@"bar"].lt_set]).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeInvalidProductIdentifier &&
          [error.bzr_productIdentifiers isEqualToSet:@[@"bar"].lt_set];
    });
  });

  it(@"should fetch info of products that appear both in the given product identifiers set and in "
     "product list provided by nether products provider", ^{
    auto product = BZRProductWithIdentifier(productIdentifier);
    auto productWithPriceInfo = BZRProductWithPriceInfo(product, 1337, @"de_DE");

    [netherProductsProviderSubject sendNext:@[product, BZRProductWithIdentifier(@"bar")]];
    OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[product]])
        .andReturn([RACSignal return:@[productWithPriceInfo]]);

    expect([store fetchProductsInfo:@[productIdentifier].lt_set])
        .will.sendValues(@[@{productIdentifier: productWithPriceInfo}]);
  });

  context(@"fetching discounted products", ^{
    __block BZRProduct *product;
    __block BZRProduct *fullPriceProduct;

    beforeEach(^{
      product =
          [BZRProductWithIdentifier(productIdentifier)
           modelByOverridingProperty:@instanceKeypath(BZRProduct, fullPriceProductIdentifier)
           withValue:@"fullFoo"];
      fullPriceProduct = BZRProductWithIdentifier(@"fullFoo");
    });

    it(@"should fetch full price product of discounted products", ^{
      auto productList = @[fullPriceProduct, product];

      [netherProductsProviderSubject sendNext:productList];

      OCMExpect([storeKitMetadataFetcher fetchProductsMetadata:productList])
          .andReturn([RACSignal return:productList]);

      expect([store fetchProductsInfo:@[productIdentifier].lt_set]).to.complete();
      OCMVerifyAll((id)storeKitMetadataFetcher);
    });

    it(@"should not send full price products that were not requested by the user", ^{
      [netherProductsProviderSubject sendNext:@[fullPriceProduct, product]];

      OCMStub([storeKitMetadataFetcher fetchProductsMetadata:OCMOCK_ANY])
          .andReturn(([RACSignal return:@[product, fullPriceProduct]]));

      expect([store fetchProductsInfo:@[productIdentifier].lt_set]).to
          .sendValues(@[@{productIdentifier: product}]);
    });

    it(@"should send full price products that were requested by the user", ^{
      auto productWithPriceInfo = BZRProductWithPriceInfo(product, 1337, @"de_DE");

      [netherProductsProviderSubject sendNext:@[fullPriceProduct, product]];

      OCMStub([storeKitMetadataFetcher fetchProductsMetadata:OCMOCK_ANY])
          .andReturn(([RACSignal return:@[productWithPriceInfo, fullPriceProduct]]));

      expect([store fetchProductsInfo:@[productIdentifier, @"fullFoo"].lt_set]).to.sendValues(@[@{
        productIdentifier: productWithPriceInfo,
        @"fullFoo": fullPriceProduct
      }]);
    });

    it(@"should not fetch full price products that don't exist in product list", ^{
      [netherProductsProviderSubject sendNext:@[product]];

      OCMStub([storeKitMetadataFetcher fetchProductsMetadata:@[product]])
          .andReturn([RACSignal return:@[product]]);

      expect([store fetchProductsInfo:@[productIdentifier].lt_set]).to
          .sendValues(@[@{productIdentifier: product}]);
    });
  });
});

context(@"handling unfinished completed transactions", ^{
  __block LLSignalTestRecorder *errorsRecorder;
  __block LLSignalTestRecorder *completedTransactionsRecorder;

  beforeEach(^{
    errorsRecorder = [store.eventsSignal testRecorder];
    completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(OCMClassMock([BZRReceiptValidationStatus class]));
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

  it(@"should not fetch receipt validation status if App Store locale was not fetched", ^{
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray<SKPaymentTransaction *> *transactions = @[transaction, transaction, transaction];
    [unhandledSuccessfulTransactionsSubject sendNext:transactions];
    [unhandledSuccessfulTransactionsSubject sendNext:transactions];
  });

  it(@"should call fetch receipt validation status once for each transactions array", ^{
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:OCMClassMock([BZRReceiptValidationStatus class])]);
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray<SKPaymentTransaction *> *transactions = @[transaction, transaction, transaction];
    [unhandledSuccessfulTransactionsSubject sendNext:transactions];
    [unhandledSuccessfulTransactionsSubject sendNext:transactions];

    OCMVerifyAllWithDelay((id)receiptValidationStatusProvider, 0.01);
  });

  it(@"should finish transaction if it appears in receipt transactions", ^{
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    auto receiptValidationStatus = [BZRReceiptValidationStatusWithExpiry(YES)
        modelByOverridingPropertyAtKeypath:
        @instanceKeypath(BZRReceiptValidationStatus, receipt.transactions)
        withValue:@[BZRTransactionWithTransactionIdentifier(@"foo")]];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    OCMStub([transaction transactionIdentifier]).andReturn(@"foo");

    OCMExpect([storeKitFacade finishTransaction:transaction]);

    [unhandledSuccessfulTransactionsSubject sendNext:@[transaction]];

    OCMVerifyAllWithDelay((id)storeKitFacade, 0.01);
  });

  it(@"should not finish transaction if it doesn't appear in receipt transactions", ^{
    appStoreLocaleProvider.appStoreLocale = [NSLocale currentLocale];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(YES)]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    OCMStub([transaction transactionIdentifier]).andReturn(@"foo");
    OCMReject([storeKitFacade finishTransaction:transaction]);

    [unhandledSuccessfulTransactionsSubject sendNext:@[transaction]];
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

  it(@"should send error sent by store kit facade", ^{
    NSError *error = OCMClassMock([NSError class]);
    [transactionsErrorEventsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should send event sent by content fetcher", ^{
    [contentFetcherEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send event sent by keychain storage", ^{
    [keychainStorageEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send event sent by store kit facade", ^{
    [storeKitFacadeEventsSubject sendNext:event];
    expect(recorder).will.sendValues(@[event]);
  });
});

context(@"KVO-compliance", ^{
  __block BZRFakeAggregatedReceiptValidationStatusProvider *validationStatusProvider;
  __block BZRFakeAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

  beforeEach(^{
    validationStatusProvider = [[BZRFakeAggregatedReceiptValidationStatusProvider alloc] init];
    acquiredViaSubscriptionProvider =  [[BZRFakeAcquiredViaSubscriptionProvider alloc] init];

    configuration = OCMClassMock([BZRStoreConfiguration class]);
    OCMStub([configuration productsProvider]).andReturn(productsProvider);
    OCMStub([configuration contentManager]).andReturn(contentManager);
    OCMStub([configuration validationStatusProvider]).andReturn(validationStatusProvider);
    OCMStub([configuration contentFetcher]).andReturn(contentFetcher);
    OCMStub([configuration acquiredViaSubscriptionProvider])
        .andReturn(acquiredViaSubscriptionProvider);
    OCMStub([configuration storeKitFacade]).andReturn(storeKitFacade);
    OCMStub([configuration periodicValidatorActivator]).andReturn(periodicValidatorActivator);
    OCMStub([configuration allowedProductsProvider]).andReturn(allowedProductsProvider);
    OCMStub([configuration netherProductsProvider]).andReturn(netherProductsProvider);
    OCMStub([configuration storeKitMetadataFetcher]).andReturn(storeKitMetadataFetcher);
    OCMStub([configuration keychainStorage]).andReturn(keychainStorage);
    OCMStub([configuration appStoreLocaleProvider]).andReturn(appStoreLocaleProvider);

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

    it(@"should not update when allowed products set hasn't changed", ^{
      auto productsSignal = [RACObserve(store, allowedProducts) testRecorder];

      allowedProductsProvider.allowedProducts = [NSSet setWithArray:@[@"foo", @"bar"]];
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

  context(@"App Store locale provider", ^{
    it(@"should update when app store locale changes", ^{
      RACSignal *appStoreLocaleSignal = [RACObserve(store, appStoreLocale) testRecorder];
      NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];

      appStoreLocaleProvider.appStoreLocale = locale;

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
