// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

#import "BZRPaymentQueue.h"
#import "BZRProductDownloadManager.h"
#import "BZRPurchaseManager.h"
#import "BZRStoreKitRequestsFactory.h"
#import "BZRTransactionRestorationManager.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "SKProductsRequest+RACSignalSupport.h"
#import "SKReceiptRefreshRequest+RACSignalSupport.h"

SpecBegin(BZRStoreKitFacade)

__block BZRPaymentQueue *paymentQueue;
__block RACSubject *unfinishedTransactionsSubject;
__block BZRPurchaseManager *purchaseManager;
__block RACSubject *unhandledTransactionsSubject;
__block BZRTransactionRestorationManager *restorationManager;
__block BZRProductDownloadManager *downloadManager;
__block id<BZRStoreKitRequestsFactory> storeKitRequestsFactory;
__block BZRStoreKitFacade *storeKitFacade;

beforeEach(^{
  paymentQueue = OCMClassMock([BZRPaymentQueue class]);
  unfinishedTransactionsSubject = [RACSubject subject];
  OCMStub([paymentQueue unfinishedTransactionsSignal]).andReturn(unfinishedTransactionsSubject);

  purchaseManager = OCMClassMock([BZRPurchaseManager class]);
  unhandledTransactionsSubject = [RACSubject subject];
  OCMStub([purchaseManager unhandledTransactionsSignal]).andReturn(unhandledTransactionsSubject);

  restorationManager = OCMClassMock([BZRTransactionRestorationManager class]);
  downloadManager = OCMClassMock([BZRProductDownloadManager class]);
  storeKitRequestsFactory = OCMProtocolMock(@protocol(BZRStoreKitRequestsFactory));
  storeKitFacade =
      [[BZRStoreKitFacade alloc] initWithPaymentQueue:paymentQueue
       purchaseManager:purchaseManager restorationManager:restorationManager
       downloadManager:downloadManager storeKitRequestsFactory:storeKitRequestsFactory];
});

context(@"fetching products metadata", ^{
  __block NSSet *productIdentifiers;
  __block SKProductsRequest *productsRequest;

  beforeEach(^{
    productIdentifiers = [NSSet setWithObject:@"foo"];
    productsRequest = OCMClassMock([SKProductsRequest class]);
    OCMStub([storeKitRequestsFactory productsRequestWithIdentifiers:OCMOCK_ANY])
        .andReturn(productsRequest);
  });

  it(@"should send value response by payments request", ^{
    SKProduct *product = OCMClassMock([SKProduct class]);
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[product]);
    OCMStub([productsRequest bzr_statusSignal]).andReturn([RACSignal return:response]);

    LLSignalTestRecorder *recorder =
        [[storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[response]);
  });

  it(@"should send error sent by products request", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([productsRequest bzr_statusSignal]).andReturn([RACSignal error:error]);

    RACSignal *signal =
        [storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers];

    expect(signal).will.sendError(error);
  });

  it(@"should start when signal is subscribed to", ^{
    [[storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers]
        subscribeNext:^(id) {}];

    OCMVerify([productsRequest start]);
  });

  it(@"should cancel when signal is disposed", ^{
    [[[storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers]
        subscribeNext:^(id) {
    }] dispose];

    OCMVerify([productsRequest cancel]);
  });
});

context(@"refreshing receipt", ^{
  __block SKReceiptRefreshRequest *refreshRequest;

  beforeEach(^{
    refreshRequest = OCMClassMock([SKReceiptRefreshRequest class]);
    OCMStub([storeKitRequestsFactory receiptRefreshRequest]).andReturn(refreshRequest);
  });

  it(@"should complete when receipt refresh request completes", ^{
    OCMStub([refreshRequest bzr_statusSignal]).andReturn([RACSignal empty]);

    LLSignalTestRecorder *recorder = [[storeKitFacade refreshReceipt] testRecorder];

    expect(recorder).will.complete();
  });

  it(@"should send error sent by receipt refresh request", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([refreshRequest bzr_statusSignal]).andReturn([RACSignal error:error]);

    RACSignal *signal = [storeKitFacade refreshReceipt];

    expect(signal).will.sendError(error);
  });

  it(@"should start when singal is subscribed to", ^{
    [[storeKitFacade refreshReceipt] subscribeNext:^(id) {}];

    OCMVerify([refreshRequest start]);
  });

  it(@"should cancel when signal is disposed", ^{
    [[[storeKitFacade refreshReceipt] subscribeNext:^(id) {}] dispose];

    OCMVerify([refreshRequest cancel]);
  });
});

context(@"purchasing products", ^{
  __block SKProduct *product;

  beforeEach(^{
    product = OCMClassMock([SKProduct class]);
  });

  it(@"should delegate purchase product call to purchase manager", ^{
    [storeKitFacade purchaseProduct:product];

    OCMVerify([purchaseManager purchaseProduct:product quantity:1]);
  });

  it(@"should delegate purchase consumable product call to purchase manager", ^{
    NSUInteger quantity = 1337;

    [storeKitFacade purchaseConsumableProduct:product quantity:quantity];

    OCMVerify([purchaseManager purchaseProduct:product quantity:quantity]);
  });
});

context(@"downloading content", ^{
  it(@"should delegate content download call to download manager", ^{
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);

    [storeKitFacade downloadContentForTransaction:transaction];

    OCMVerify([downloadManager downloadContentForTransaction:transaction]);
  });
});

context(@"restoring completed transactions", ^{
  it(@"should delegate restore completed transactions call to restoration manager", ^{
    [storeKitFacade restoreCompletedTransactions];

    OCMVerify([restorationManager restoreCompletedTransactions]);
  });
});

context(@"finishing transactions", ^{
  it(@"should delegate finish transaction call to payment queue", ^{
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);

    [storeKitFacade finishTransaction:transaction];

    OCMVerify([paymentQueue finishTransaction:transaction]);
  });
});

context(@"sending unhandled transactions errors", ^{
  it(@"should complete when object is deallocated", ^{
    BZRStoreKitFacade * __weak weakStoreKitFacade;
    RACSignal *transactionsErrorsSignal;

    @autoreleasepool {
      BZRStoreKitFacade *storeKitFacade =
          [[BZRStoreKitFacade alloc] initWithPaymentQueue:paymentQueue
           purchaseManager:purchaseManager restorationManager:restorationManager
           downloadManager:downloadManager storeKitRequestsFactory:storeKitRequestsFactory];
      weakStoreKitFacade = storeKitFacade;

      transactionsErrorsSignal = storeKitFacade.transactionsErrorsSignal;
    }
    expect(weakStoreKitFacade).to.beNil();
    expect(transactionsErrorsSignal).will.complete();
  });

  it(@"should send error wrapping an unhandled transaction when purchase manager sends it", ^{
    LLSignalTestRecorder *recorder = [storeKitFacade.transactionsErrorsSignal testRecorder];
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    [unhandledTransactionsSubject sendNext:transaction];

    expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == BZRErrorCodeUnhandledTransactionReceived &&
          error.bzr_transaction == transaction;
    });
  });
});

context(@"handling unfinished transactions", ^{
  __block LLSignalTestRecorder *unfinishedCompletedTransactionsRecorder;

  beforeEach(^{
    unfinishedCompletedTransactionsRecorder =
        [storeKitFacade.unfinishedSuccessfulTransactionsSignal testRecorder];
  });

  context(@"purchasing transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchasing);
    });

    it(@"should not finish transaction", ^{
      OCMReject([paymentQueue finishTransaction:OCMOCK_ANY]);

      [unfinishedTransactionsSubject sendNext:@[transaction]];
    });

    it(@"should not send transaction as successful", ^{
      [unfinishedTransactionsSubject sendNext:@[transaction]];

      expect(unfinishedCompletedTransactionsRecorder).will.sendValues(@[@[]]);
    });
  });

  context(@"failed transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
    });

    it(@"should finish transaction", ^{
      [unfinishedTransactionsSubject sendNext:@[transaction]];
      OCMVerify([storeKitFacade finishTransaction:transaction]);
    });

    it(@"should send error wrapping a failed transaction", ^{
      LLSignalTestRecorder *recorder = [storeKitFacade.transactionsErrorsSignal testRecorder];
      SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
      [unfinishedTransactionsSubject sendNext:@[transaction]];

      expect(recorder).will.matchValue(0, ^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodePurchaseFailed &&
            error.bzr_transaction == transaction;
      });
    });

    it(@"should not send transaction as successful", ^{
      [unfinishedTransactionsSubject sendNext:@[transaction]];

      expect(unfinishedCompletedTransactionsRecorder).will.sendValues(@[@[]]);
    });
  });

  context(@"purchased transaction", ^{
    __block SKPaymentTransaction *transaction;

    beforeEach(^{
      transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    });

    it(@"should not finish transaction", ^{
      OCMReject([storeKitFacade finishTransaction:transaction]);
      [unfinishedTransactionsSubject sendNext:@[transaction]];
    });

    it(@"should send transaction as successful", ^{
      [unfinishedTransactionsSubject sendNext:@[transaction]];

      expect(unfinishedCompletedTransactionsRecorder).will.sendValues(@[@[transaction]]);
    });
  });
});

SpecEnd
