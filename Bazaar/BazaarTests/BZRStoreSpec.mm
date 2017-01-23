// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidatorActivator.h"
#import "BZRProduct+SKProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
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
#import "NSErrorCodes+Bazaar.h"
#import "NSError+Bazaar.h"

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
__block BZRProductContentProvider *contentProvider;
__block BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
__block BZRStoreKitFacade *storeKitFacade;
__block BZRPeriodicReceiptValidatorActivator *periodicValidatorActivator;
__block id<BZRProductsVariantSelector> variantSelector;
__block id<BZRReceiptValidationParametersProvider> validationParametersProvider;
__block NSBundle *bundle;
__block NSFileManager *fileManager;
__block RACSubject *productsProviderEventsSubject;
__block RACSubject *receiptValidationStatusProviderEventsSubject;
__block RACSubject *acquiredViaSubscriptionProviderEventsSubject;
__block RACSubject *periodicReceiptValidatorActivatorEventsSubject;
__block RACSubject *transactionsErrorEventsSubject;
__block RACSubject *unfinishedSuccessfulTransactionsSubject;
__block BZRStoreConfiguration *configuration;
__block BZRStore *store;
__block NSString *productIdentifier;

beforeEach(^{
  productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  contentManager = OCMClassMock([BZRProductContentManager class]);
  receiptValidationStatusProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
  contentProvider = OCMClassMock([BZRProductContentProvider class]);
  acquiredViaSubscriptionProvider = OCMClassMock([BZRAcquiredViaSubscriptionProvider class]);
  storeKitFacade = OCMClassMock([BZRStoreKitFacade class]);
  periodicValidatorActivator = OCMClassMock([BZRPeriodicReceiptValidatorActivator class]);
  variantSelector = OCMProtocolMock(@protocol(BZRProductsVariantSelector));
  validationParametersProvider = OCMClassMock([BZRReceiptValidationParametersProvider class]);
  bundle = OCMClassMock([NSBundle class]);
  fileManager = OCMClassMock([NSFileManager class]);
  id<BZRProductsVariantSelectorFactory> variantSelectorFactory =
      OCMProtocolMock(@protocol(BZRProductsVariantSelectorFactory));
  OCMStub([variantSelectorFactory
      productsVariantSelectorWithProductDictionary:OCMOCK_ANY error:[OCMArg anyObjectRef]])
      .andReturn(variantSelector);

  productsProviderEventsSubject = [RACSubject subject];
  receiptValidationStatusProviderEventsSubject = [RACSubject subject];
  acquiredViaSubscriptionProviderEventsSubject = [RACSubject subject];
  periodicReceiptValidatorActivatorEventsSubject = [RACSubject subject];
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
  OCMStub([storeKitFacade transactionsErrorEventsSignal])
      .andReturn(transactionsErrorEventsSubject);
  OCMStub([storeKitFacade unfinishedSuccessfulTransactionsSignal])
      .andReturn(unfinishedSuccessfulTransactionsSubject);

  configuration =
      [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:[LTPath pathWithPath:@"foo"]
                                          countryToTierDictionaryPath:[LTPath pathWithPath:@"bar"]];
  configuration.productsProvider = productsProvider;
  configuration.contentManager = contentManager;
  configuration.validationStatusProvider = receiptValidationStatusProvider;
  configuration.contentProvider = contentProvider;
  configuration.acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;
  configuration.storeKitFacade = storeKitFacade;
  configuration.periodicValidatorActivator = periodicValidatorActivator;
  configuration.variantSelectorFactory = variantSelectorFactory;
  configuration.validationParametersProvider = validationParametersProvider;
  configuration.applicationReceiptBundle = bundle;
  configuration.fileManager = fileManager;
  store = [[BZRStore alloc] initWithConfiguration:configuration];
  productIdentifier = @"foo";
});

context(@"getting path to content", ^{
  it(@"should delegate path to content to content manager", ^{
    LTPath *path = [LTPath pathWithPath:@"bar"];
    OCMStub([contentManager pathToContentDirectoryOfProduct:productIdentifier]).andReturn(path);

    expect([store pathToContentOfProduct:productIdentifier]).to.equal(path);
    OCMVerify([contentManager pathToContentDirectoryOfProduct:productIdentifier]);
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
  __block NSSet *acquiredViaSubscription;

  beforeEach(^{
    acquiredViaSubscription = [NSSet setWithObject:@"bar"];
    OCMStub([acquiredViaSubscriptionProvider productsAcquiredViaSubscription])
        .andReturn(acquiredViaSubscription);
  });

  it(@"should return purchased product when subsciption doesn't exist", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    BZRReceiptInfo *receipt =
        [receiptValidationStatus.receipt
         modelByOverridingProperty:@keypath(receiptValidationStatus.receipt, subscription)
                         withValue:nil];
    receiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingProperty:@keypath(receiptValidationStatus, receipt) withValue:receipt];
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    expect(store.allowedProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });

  it(@"should return purchased product when subsciption is expired", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, YES);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    expect(store.allowedProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });

  it(@"should return in-app purchases unified with acquired via subscription when subsciption is "
      "not expired", ^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
    OCMStub([receiptValidationStatusProvider receiptValidationStatus])
        .andReturn(receiptValidationStatus);

    expect(store.allowedProducts).to
        .equal([acquiredViaSubscription setByAddingObject:productIdentifier]);
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

context(@"downloaded products", ^{
  beforeEach(^{
    OCMStub([variantSelector selectedVariantForProductWithIdentifier:productIdentifier])
        .andReturn(productIdentifier);
  });
  it(@"should treat product without content as downloaded", ^{
    BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });

  it(@"should filter products without downloaded content", ^{
    BZRStubProductDictionaryToReturnProductWithContent(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet set]);
  });

  it(@"should add product with downloaded content", ^{
    BZRStubProductDictionaryToReturnProductWithContent(productIdentifier, productsProvider);
    OCMStub([contentManager pathToContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([LTPath pathWithPath:@"/baz"]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
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
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductIdentifer;
    });
  });

  it(@"should send error when product given by variant selector doesn't exist", ^{
    NSArray<BZRProduct *> *productList = @[
      BZRProductWithIdentifier(@"bar"),
      BZRProductWithIdentifier(@"baz")
    ];

    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:productList]);
    expect([store purchaseProduct:@"bar"]).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductIdentifer;
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

  context(@"product exists", ^{
    beforeEach(^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
    });

    it(@"should add product to acquired via subscription if subscription exists and not expired", ^{
      BZRReceiptValidationStatus *receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, NO);
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);

      expect([store purchaseProduct:productIdentifier]).will.complete();
      OCMVerify([acquiredViaSubscriptionProvider
                 addAcquiredViaSubscriptionProduct:productIdentifier]);
    });

    context(@"purchasing through store kit", ^{
      beforeEach(^{
        BZRReceiptValidationStatus *receiptValidationStatus =
            BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(productIdentifier, YES);
        OCMStub([receiptValidationStatusProvider receiptValidationStatus])
            .andReturn(receiptValidationStatus);
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
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        expect([store purchaseProduct:@"bar"]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
      });

      it(@"should call validate receipt when store kit signal finishes", ^{
        OCMStub([storeKitFacade purchaseProduct:OCMOCK_ANY]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
        OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
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
  it(@"should send error when content provider errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([contentProvider fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal error:error]);

    expect([store fetchProductContent:productIdentifier]).will.sendError(error);
  });

  it(@"should send path sent by content provider", ^{
    BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];
    LTPath *path = [LTPath pathWithPath:@"bar"];
    OCMExpect([contentProvider fetchProductContent:
        [OCMArg checkWithBlock:^BOOL(BZRProduct *product) {
          return [product.identifier isEqualToString:productIdentifier];
        }]]).andReturn([RACSignal return:path]);

    LLSignalTestRecorder *recorder = [[store fetchProductContent:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[path]);
    OCMVerifyAll((id)contentProvider);
  });

  it(@"should update downloaded content products", ^{
    BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LTPath *path = [LTPath pathWithPath:@"bar"];
    OCMStub([contentProvider fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal return:path]);

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
    OCMVerifyAll((id)contentProvider);
  });

  it(@"should update downloaded content products", ^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LTPath *path = [LTPath pathWithPath:@"bar"];
    OCMStub([contentProvider fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal return:path]);
    expect(store.downloadedContentProducts).will.equal([NSSet setWithObject:productIdentifier]);
    OCMStub([contentManager deleteContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    expect([store deleteProductContent:productIdentifier]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet set]);
  });
});

context(@"refreshing receipt", ^{
  static NSString * const kTransactionRestorationSharedExamples =
      @"TransactionRestorationSharedExamples";

  sharedExamplesFor(kTransactionRestorationSharedExamples, ^(NSDictionary *) {
    context(@"transaction restoration", ^{
      beforeEach(^{
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);
      });

      it(@"should use StoreKit to restore completed transactions", ^{
        OCMExpect([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);

        expect([store refreshReceipt]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
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

      it(@"should err if transaction restoration errs", ^{
        NSError *error = [NSError lt_errorWithCode:1337];
        OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal error:error]);

        LLSignalTestRecorder *recorder = [[store refreshReceipt] testRecorder];
        
        expect(recorder).will.sendError(error);
      });
    });

    context(@"receipt validation", ^{
      __block BZRReceiptValidationStatus *receiptValidationStatus;

      beforeEach(^{
        OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
        receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
      });

      it(@"should validate the receipt if restoration completed successfully", ^{
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
    });
  });

  context(@"receipt file is not available", ^{
    context(@"refreshing receipt", ^{
      beforeEach(^{
        OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);
      });

      it(@"should use StoreKit to refresh the receipt if the receipt URL is nil", ^{
        OCMExpect([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);

        expect([store refreshReceipt]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
      });

      it(@"should use StoreKit to refresh the receipt if the receipt file does not exist", ^{
        OCMStub([bundle appStoreReceiptURL]).andReturn([NSURL URLWithString:@"/foo"]);
        OCMStub([fileManager fileExistsAtPath:@"/foo"]).andReturn(NO);
        OCMExpect([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);

        expect([store refreshReceipt]).will.complete();
        OCMVerifyAll((id)storeKitFacade);
      });

      it(@"should err if receipt refreshing failed", ^{
        NSError *error = [NSError lt_errorWithCode:1337];
        OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal error:error]);

        expect([store refreshReceipt]).will.sendError(error);
      });
    });

    context(@"transaction restoration", ^{
      beforeEach(^{
        OCMStub([storeKitFacade refreshReceipt]).andReturn([RACSignal empty]);
      });

      itShouldBehaveLike(kTransactionRestorationSharedExamples, @{});
    });
  });

  context(@"receipt file is available", ^{
    beforeEach(^{
      OCMStub([bundle appStoreReceiptURL]).andReturn([NSURL URLWithString:@"/foo"]);
      OCMStub([fileManager fileExistsAtPath:@"/foo"]).andReturn(YES);
    });

    context(@"refreshing receipt", ^{
      it(@"should not use StoreKit to refresh the receipt if the receipt file exists", ^{
        OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);
        OCMReject([storeKitFacade refreshReceipt]);
        expect([store refreshReceipt]).will.complete();
      });
    });

    context(@"transaction restoration", ^{
      itShouldBehaveLike(kTransactionRestorationSharedExamples, @{});
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

  it(@"should refetch product list if an error occured during prefetch", ^{
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

  it(@"should dealloc when all strong references are relinquished", ^{
    BZRStore * __weak weakStore;
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal error:error]);

    RACSignal *productListSignal;
    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      expect(store.eventsSignal).will.matchValue(0, ^BOOL(BZREvent *event) {
        NSError *error = event.eventError;
        return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
            [event.eventType isEqual:$(BZREventTypeCriticalError)];
      });

      OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);

      productListSignal = [store productList];
    }
    expect(productListSignal).will.complete();
    expect(weakStore).to.beNil();
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

context(@"handling unfinished completed transactions", ^{
  __block LLSignalTestRecorder *errorsRecorder;
  __block LLSignalTestRecorder *completedTransactionsRecorder;

  beforeEach(^{
    errorsRecorder = [store.eventsSignal testRecorder];
    completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
  });

  it(@"should complete when object is deallocated", ^{
    BZRStore * __weak weakStore;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
    }
    expect(completedTransactionsRecorder).will.complete();
  });

  it(@"should call fetch receipt validation status once for each transactions array", ^{
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray<SKPaymentTransaction *> *transactions = @[transaction, transaction, transaction];
    [unfinishedSuccessfulTransactionsSubject sendNext:transactions];

    OCMVerifyAll((id)receiptValidationStatusProvider);
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

    configuration.validationStatusProvider = validationStatusProvider;
    configuration.acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;
    configuration.validationParametersProvider = validationParametersProvider;

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
    it(@"should update when acquired via subscription list is changed", ^{
      validationStatusProvider.receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
      RACSignal *productsSignal = [RACObserve(store, allowedProducts) testRecorder];
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObjects:@"foo", @"bar", nil];

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObjects:@"foo", @"bar", nil]
      ]);
    });

    it(@"should update when purchased products is changed", ^{
      validationStatusProvider.receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
      RACSignal *productsSignal = [RACObserve(store, allowedProducts) testRecorder];
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"foo", NO);

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObjects:@"foo", nil]
      ]);
    });

    it(@"should remove acquired via subscription products when subscribption expires", ^{
      validationStatusProvider.receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:@"foo"];
      RACSignal *productsSignal = [RACObserve(store, allowedProducts) testRecorder];
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"bar", NO);
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"bar", YES);

      expect(productsSignal).to.sendValues(@[
        [NSSet setWithObject:@"foo"],
        [NSSet setWithObjects:@"foo", @"bar", nil],
        [NSSet setWithObject:@"bar"]
      ]);
    });

    it(@"should add acquried via subscription products when subscription renews", ^{
      validationStatusProvider.receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
      acquiredViaSubscriptionProvider.productsAcquiredViaSubscription =
          [NSSet setWithObject:@"foo"];
      RACSignal *productsSignal = [RACObserve(store, allowedProducts) testRecorder];
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"bar", YES);
      validationStatusProvider.receiptValidationStatus =
          BZRReceiptValidationStatusWithInAppPurchaseAndExpiry(@"bar", NO);

      expect(productsSignal).to.sendValues(@[
        [NSSet set],
        [NSSet setWithObject:@"bar"],
        [NSSet setWithObjects:@"foo", @"bar", nil]
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
});

SpecEnd
