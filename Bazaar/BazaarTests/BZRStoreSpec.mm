// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRAcquiredViaSubscriptionProvider.h"
#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRProduct.h"
#import "BZRProductContentManager.h"
#import "BZRProductContentProvider.h"
#import "BZRProductPriceInfo.h"
#import "BZRProductsProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRStoreConfiguration.h"
#import "BZRStoreKitFacade.h"
#import "BZRStoreKitFacadeFactory.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSError+Bazaar.h"

static SKProductsResponse *BZRProductsResponseWithProductWithProperties(NSString *productIdentifier,
    NSDecimalNumber *price, NSLocale *locale);
static SKProductsResponse *BZRProductsResponseWithProduct(NSString *productIdentifier);
static void BZRStubProductDictionaryToReturnProduct(BZRProduct *product,
    id<BZRProductsProvider> productsProvider, BZRStoreKitFacade *storeKitFacade);

static void BZRStubProductDictionaryToReturnProductWithIdentifier(NSString *productIdentifier,
    id<BZRProductsProvider> productsProvider, BZRStoreKitFacade *storeKitFacade) {
  BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
  BZRStubProductDictionaryToReturnProduct(product, productsProvider, storeKitFacade);
}

static void BZRStubProductDictionaryToReturnProductWithContent(NSString *productIdentifier,
    id<BZRProductsProvider> productsProvider, BZRStoreKitFacade *storeKitFacade) {
  BZRProduct *product = BZRProductWithIdentifierAndContent(productIdentifier);
  BZRStubProductDictionaryToReturnProduct(product, productsProvider, storeKitFacade);
}

static void BZRStubProductDictionaryToReturnProduct(BZRProduct *product,
    id<BZRProductsProvider> productsProvider, BZRStoreKitFacade *storeKitFacade) {
  OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
  SKProductsResponse *response = BZRProductsResponseWithProduct(product.identifier);
  OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
      .andReturn([RACSignal return:response]);
}

static SKProductsResponse *BZRProductsResponseWithProduct(NSString *productIdentifier) {
  return BZRProductsResponseWithProductWithProperties(productIdentifier, [NSDecimalNumber one],
                                                      [NSLocale currentLocale]);
}

static SKProductsResponse *BZRProductsResponseWithProductWithProperties(NSString *productIdentifier,
    NSDecimalNumber *price, NSLocale *locale) {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product price]).andReturn(price);
  OCMStub([product priceLocale]).andReturn(locale);
  OCMStub([product productIdentifier]).andReturn(productIdentifier);
  SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
  OCMStub([response products]).andReturn(@[product]);

  return response;
}

SpecBegin(BZRStore)

__block id<BZRProductsProvider> productsProvider;
__block BZRProductContentManager *contentManager;
__block BZRCachedReceiptValidationStatusProvider *receiptValidationStatusProvider;
__block BZRProductContentProvider *contentProvider;
__block BZRAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;
__block BZRStoreKitFacade *storeKitFacade;
__block NSBundle *bundle;
__block NSFileManager *fileManager;
__block RACSubject *receiptValidationStatusProviderErrorsSubject;
__block RACSubject *acquiredViaSubscriptionProviderErrorsSubject;
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
  bundle = OCMClassMock([NSBundle class]);
  fileManager = OCMClassMock([NSFileManager class]);
  BZRStoreKitFacadeFactory *storeKitFacadeFactory = OCMClassMock([BZRStoreKitFacadeFactory class]);
  OCMStub([storeKitFacadeFactory storeKitFacadeWithUnfinishedTransactionsSubject:OCMOCK_ANY])
      .andReturn(storeKitFacade);

  receiptValidationStatusProviderErrorsSubject = [RACSubject subject];
  acquiredViaSubscriptionProviderErrorsSubject = [RACSubject subject];
  OCMStub([receiptValidationStatusProvider nonCriticalErrorsSignal])
      .andReturn(receiptValidationStatusProviderErrorsSubject);
  OCMStub([acquiredViaSubscriptionProvider storageErrorsSignal])
      .andReturn(acquiredViaSubscriptionProviderErrorsSubject);

  configuration =
      [[BZRStoreConfiguration alloc] initWithProductsListJSONFilePath:[LTPath pathWithPath:@"foo"]];
  configuration.productsProvider = productsProvider;
  configuration.contentManager = contentManager;
  configuration.validationStatusProvider = receiptValidationStatusProvider;
  configuration.contentProvider = contentProvider;
  configuration.acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;
  configuration.storeKitFacadeFactory = storeKitFacadeFactory;
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

    expect([store purchasedProducts]).to.equal([NSSet setWithObject:@"foo"]);
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
  it(@"should treat product without content as downloaded", ^{
    BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider,
                                                          storeKitFacade);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });

  it(@"should filter products without downloaded content", ^{
    BZRStubProductDictionaryToReturnProductWithContent(productIdentifier, productsProvider,
                                                       storeKitFacade);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet set]);
  });

  it(@"should add product with downloaded content", ^{
    BZRStubProductDictionaryToReturnProductWithContent(productIdentifier, productsProvider,
                                                       storeKitFacade);
    OCMStub([contentManager pathToContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([LTPath pathWithPath:@"/baz"]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    expect([store productList]).will.complete();
    expect(store.downloadedContentProducts).to.equal([NSSet setWithObject:productIdentifier]);
  });
});

context(@"purchasing products", ^{
  it(@"should send error when product doesn't exist", ^{
    expect([store purchaseProduct:productIdentifier]).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeInvalidProductIdentifer;
    });
  });

  context(@"product exists", ^{
    beforeEach(^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider,
                                                            storeKitFacade);
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
        BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
        BZRStubProductDictionaryToReturnProduct(product, productsProvider, storeKitFacade);
        OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
        SKProductsResponse *response = BZRProductsResponseWithProduct(productIdentifier);
        OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
            .andReturn([RACSignal return:response]);
        OCMExpect([storeKitFacade purchaseProduct:[OCMArg checkWithBlock:^BOOL(SKProduct *product) {
          return [product.productIdentifier isEqualToString:productIdentifier];
        }]]).andReturn([RACSignal empty]);
        OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
            .andReturn([RACSignal empty]);

        expect([store purchaseProduct:productIdentifier]).will.complete();
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
    LTPath *path = [LTPath pathWithPath:@"bar"];
    OCMStub([contentProvider fetchProductContent:OCMOCK_ANY]).andReturn([RACSignal return:path]);

    LLSignalTestRecorder *recorder = [[store fetchProductContent:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[path]);
  });

  it(@"should update downloaded content products", ^{
    BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider,
                                                          storeKitFacade);
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
    OCMStub([contentManager deleteContentDirectoryOfProduct:OCMOCK_ANY])
        .andReturn([RACSignal empty]);

    expect([store deleteProductContent:productIdentifier]).will.complete();
  });

  it(@"should update downloaded content products", ^{
      BZRStubProductDictionaryToReturnProductWithIdentifier(productIdentifier, productsProvider,
                                                            storeKitFacade);
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
  it(@"should call fetch product list and fetch metadata only once", ^{
    BZRProduct *product = BZRProductWithIdentifier(productIdentifier);
    BZRStubProductDictionaryToReturnProduct(product, productsProvider, storeKitFacade);
    OCMExpect([productsProvider fetchProductList]).andReturn([RACSignal return:@[product]]);
    SKProductsResponse *response = BZRProductsResponseWithProduct(product.identifier);
    OCMExpect([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LLSignalTestRecorder *recorder = [[store productList] testRecorder];
    expect(recorder).will.complete();
    recorder = [[store productList] testRecorder];
    expect(recorder).will.complete();

    OCMVerify([productsProvider fetchProductList]);
    OCMVerify([storeKitFacade fetchMetadataForProductsWithIdentifiers:
               [NSSet setWithObject:productIdentifier]]);
  });

  it(@"should send empty set even when facade sends products", ^{
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[]]);
    SKProductsResponse *response = BZRProductsResponseWithProduct(productIdentifier);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[[NSSet set]]);
  });

  it(@"should send error when failed to fetch product list", ^{
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:underlyingError]);
    SKProductsResponse *response = BZRProductsResponseWithProduct(productIdentifier);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
          error.lt_underlyingError == underlyingError;
    });
  });

  it(@"should send error when failed to fetch products metadata", ^{
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[]]);
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal error:underlyingError]);
    store = [[BZRStore alloc] initWithConfiguration:configuration];

    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
          error.lt_underlyingError == underlyingError;
    });
  });

  context(@"subscribers only products", ^{
    __block BZRProduct *subscribersOnlyProduct;

    beforeEach(^{
      subscribersOnlyProduct =
          [BZRProductWithIdentifier(productIdentifier)
           modelByOverridingProperty:@instanceKeypath(BZRProduct, isSubscribersOnly)
                           withValue:@YES];
    });

    it(@"should not fetch metadata for subscribers only products", ^{
      OCMStub([productsProvider fetchProductList])
          .andReturn([RACSignal return:@[subscribersOnlyProduct]]);

      SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
      OCMStub([response products]).andReturn(@[]);
      OCMExpect([storeKitFacade fetchMetadataForProductsWithIdentifiers:[NSSet set]])
          .andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      expect([store productList]).will.complete();

      OCMVerifyAll((id)storeKitFacade);
    });

    it(@"should merge subscribers only products with products with price info", ^{
      BZRProduct *notForSubscribersOnlyProduct = BZRProductWithIdentifier(@"bar");
      RACSignal *productList =
          [RACSignal return:@[subscribersOnlyProduct, notForSubscribersOnlyProduct]];
      OCMStub([productsProvider fetchProductList]).andReturn(productList);

      SKProductsResponse *response = BZRProductsResponseWithProduct(@"bar");
      OCMExpect([storeKitFacade fetchMetadataForProductsWithIdentifiers:
                 [NSSet setWithObject:@"bar"]]).andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      LLSignalTestRecorder *recorder = [[store productList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        BZRProduct *priceInfoProduct =
            [[productList allObjects] lt_filter:^BOOL(BZRProduct *product) {
              return !product.isSubscribersOnly;
            }].firstObject;
        BZRProduct *subscribersOnlyProduct =
            [[productList allObjects] lt_filter:^BOOL(BZRProduct *product) {
              return product.isSubscribersOnly;
            }].firstObject;

        return [productList count] == 2 && [priceInfoProduct.identifier isEqualToString:@"bar"] &&
            priceInfoProduct.priceInfo &&
            [subscribersOnlyProduct.identifier isEqualToString:productIdentifier] &&
            !subscribersOnlyProduct.priceInfo;
      });
      OCMVerifyAll((id)storeKitFacade);
    });
  });

  context(@"products provider sends one product", ^{
    beforeEach(^{
      BZRProduct *bazaarProduct = BZRProductWithIdentifier(productIdentifier);
      OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[bazaarProduct]]);
    });

    it(@"should return empty set if facade returns a response without products", ^{
      SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
      OCMStub([response products]).andReturn(@[]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      LLSignalTestRecorder *recorder = [[store productList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[[NSSet set]]);
    });

    it(@"should return set with product if facade returns a response with the same product", ^{
      SKProductsResponse *response = BZRProductsResponseWithProduct(productIdentifier);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      LLSignalTestRecorder *recorder = [[store productList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
        return [productList count] == 1 &&
            [productList allObjects].firstObject.identifier == productIdentifier;
      });
    });

    it(@"should return empty set with product if facade returns a response with another product", ^{
      SKProductsResponse *response = BZRProductsResponseWithProduct(@"bar");
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];

      LLSignalTestRecorder *recorder = [[store productList] testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[[NSSet set]]);
    });

    it(@"should dealloc when all strong references are relinquished", ^{
      BZRStore * __weak weak_store;
      SKProductsResponse *response = BZRProductsResponseWithProduct(productIdentifier);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal return:response]);

      @autoreleasepool {
        BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
        weak_store = store;
      }
      expect(weak_store).to.beNil();
    });
  });

  it(@"should send price info correctly", ^{
    BZRProduct *bazaarProduct = BZRProductWithIdentifier(productIdentifier);
    OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[bazaarProduct]]);
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
    NSDecimalNumber *price = [NSDecimalNumber decimalNumberWithString:@"1337.37"];
    SKProductsResponse *response =
        BZRProductsResponseWithProductWithProperties(productIdentifier, price, locale);
    OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
        .andReturn([RACSignal return:response]);

    store = [[BZRStore alloc] initWithConfiguration:configuration];
    LLSignalTestRecorder *recorder = [[store productList] testRecorder];

    expect(recorder).will.matchValue(0, ^BOOL(NSSet<BZRProduct *> *productList) {
      BZRProductPriceInfo *priceInfo = [productList allObjects].firstObject.priceInfo;
      return [priceInfo.localizedPrice isEqualToString:@"1.337,37 €"] &&
          [priceInfo.price isEqualToNumber:price];
    });
  });
});

context(@"handling unfinished transactions", ^{
  __block RACSubject *unfinishedSubject;
  __block LLSignalTestRecorder *errorsRecorder;
  __block LLSignalTestRecorder *completedTransactionsRecorder;

  beforeEach(^{
    BZRStoreKitFacadeFactory *storeKitFacadeFactory =
        OCMClassMock([BZRStoreKitFacadeFactory class]);
    OCMStub([storeKitFacadeFactory storeKitFacadeWithUnfinishedTransactionsSubject:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSubject *subject;
          [invocation getArgument:&subject atIndex:2];
          unfinishedSubject = subject;
        })
        .andReturn(storeKitFacade);
    configuration.storeKitFacadeFactory = storeKitFacadeFactory;
    store = [[BZRStore alloc] initWithConfiguration:configuration];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal empty]);
    OCMStub([storeKitFacade restoreCompletedTransactions]).andReturn([RACSignal empty]);
    errorsRecorder = [store.errorsSignal testRecorder];
    completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
  });

  it(@"should completed when object is deallocated", ^{
    BZRStore * __weak weakStore;
    RACSignal *completedTransactionsSignal;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      completedTransactionsSignal = store.completedTransactionsSignal;
    }
    expect(completedTransactionsSignal).will.complete();
  });

  context(@"purchasing transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchasing);
    });

    it(@"should not finish nor fetch receipt validation status", ^{
      OCMReject([storeKitFacade finishTransaction:OCMOCK_ANY]);
      OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

      [unfinishedSubject sendNext:@[transaction]];
    });

    it(@"should not send transaction as finished", ^{
      BZRStore * __weak weakStore;
      LLSignalTestRecorder *completedTransactionsRecorder;

      @autoreleasepool {
        BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
        weakStore = store;
        completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
        [unfinishedSubject sendNext:@[transaction]];
      }
      expect(completedTransactionsRecorder).will.complete();
      expect(completedTransactionsRecorder).will.sendValuesWithCount(0);
    });
  });

  context(@"failed transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
    });

    it(@"should finish and not fetch receipt validation status", ^{
      OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);
      [unfinishedSubject sendNext:@[transaction]];
      OCMVerify([storeKitFacade finishTransaction:transaction]);
    });

    it(@"should not send transaction as finished", ^{
      BZRStore * __weak weakStore;
      LLSignalTestRecorder *completedTransactionsRecorder;

      @autoreleasepool {
        BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
        weakStore = store;
        completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
        [unfinishedSubject sendNext:@[transaction]];
      }
      expect(completedTransactionsRecorder).will.complete();
      expect(completedTransactionsRecorder).will.sendValuesWithCount(0);
    });
  });

  context(@"purchased transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    });

    it(@"should finish and fetch receipt validation status", ^{
      [unfinishedSubject sendNext:@[transaction]];
      OCMVerify([storeKitFacade finishTransaction:transaction]);
      OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    });

    it(@"should send transaction as finished", ^{
      BZRStore * __weak weakStore;
      LLSignalTestRecorder *completedTransactionsRecorder;

      @autoreleasepool {
        BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
        weakStore = store;
        completedTransactionsRecorder = [store.completedTransactionsSignal testRecorder];
        [unfinishedSubject sendNext:@[transaction]];
      }

      expect(completedTransactionsRecorder).will.complete();
      expect(completedTransactionsRecorder).will.sendValues(@[transaction]);
    });
  });

  it(@"should call fetch receipt validation status once for each transactions array", ^{
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray *transactions = @[transaction, transaction, transaction];
    [unfinishedSubject sendNext:transactions];

    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
  });

  it(@"should receive finished transactions when new subscriber subscribes", ^{
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    NSArray *transactions = @[transaction, transaction, transaction];
    [unfinishedSubject sendNext:transactions];

    LLSignalTestRecorder *recorder = [store.completedTransactionsSignal testRecorder];

    expect(recorder).will.sendValues(transactions);
  });
});

context(@"errors signal", ^{
  it(@"should completed when object is deallocated", ^{
    BZRStore * __weak weakStore;
    RACSignal *errorsSignal;

    @autoreleasepool {
      BZRStore *store = [[BZRStore alloc] initWithConfiguration:configuration];
      weakStore = store;
      errorsSignal = store.errorsSignal;
    }
    expect(errorsSignal).will.complete();
  });

  context(@"errors while fetching product list", ^{
    it(@"should send error when products provider errs", ^{
      NSError *underlyingError = OCMClassMock([NSError class]);
      OCMStub([productsProvider fetchProductList]).andReturn([RACSignal error:underlyingError]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
      LLSignalTestRecorder *recorder = [store.errorsSignal testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
            error.lt_underlyingError == underlyingError;
      });
    });

    it(@"should send error when store kit facade errs", ^{
      BZRProduct *bazaarProduct = BZRProductWithIdentifier(productIdentifier);
      OCMStub([productsProvider fetchProductList]).andReturn([RACSignal return:@[bazaarProduct]]);
      NSError *underlyingError = OCMClassMock([NSError class]);
      OCMStub([storeKitFacade fetchMetadataForProductsWithIdentifiers:OCMOCK_ANY])
          .andReturn([RACSignal error:underlyingError]);
      store = [[BZRStore alloc] initWithConfiguration:configuration];
      LLSignalTestRecorder *recorder = [store.errorsSignal testRecorder];

      expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeFetchingProductListFailed &&
            error.lt_underlyingError == underlyingError;
      });
    });
  });

  it(@"should send error when receipt validation status provider sends error", ^{
    NSError *error = OCMClassMock([NSError class]);
    LLSignalTestRecorder *recorder = [store.errorsSignal testRecorder];
    [receiptValidationStatusProviderErrorsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should send error when acquired via subscription provider sends error", ^{
    NSError *error = OCMClassMock([NSError class]);
    LLSignalTestRecorder *recorder = [store.errorsSignal testRecorder];
    [acquiredViaSubscriptionProviderErrorsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });
});

context(@"KVO-compliance", ^{
  __block BZRFakeCachedReceiptValidationStatusProvider *validationStatusProvider;
  __block BZRFakeAcquiredViaSubscriptionProvider *acquiredViaSubscriptionProvider;

  beforeEach(^{
    validationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
    acquiredViaSubscriptionProvider =  [[BZRFakeAcquiredViaSubscriptionProvider alloc] init];

    configuration.validationStatusProvider = validationStatusProvider;
    configuration.acquiredViaSubscriptionProvider = acquiredViaSubscriptionProvider;

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
});

SpecEnd
