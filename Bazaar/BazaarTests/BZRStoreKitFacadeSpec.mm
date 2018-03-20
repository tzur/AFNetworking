// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitFacade.h"

#import "BZREvent.h"
#import "BZRPaymentQueueAdapter.h"
#import "BZRProductDownloadManager.h"
#import "BZRPurchaseManager.h"
#import "BZRStoreKitRequestsFactory.h"
#import "BZRTransactionRestorationManager.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "SKProductsRequest+RACSignalSupport.h"
#import "SKReceiptRefreshRequest+RACSignalSupport.h"

SpecBegin(BZRStoreKitFacade)

__block BZRPaymentQueueAdapter *paymentQueueAdapter;
__block RACSubject *paymentQueueEventsSubject;
__block RACSubject *unfinishedTransactionsSubject;
__block BZRPurchaseManager *purchaseManager;
__block RACSubject *unhandledTransactionsSubject;
__block BZRTransactionRestorationManager *restorationManager;
__block BZRProductDownloadManager *downloadManager;
__block id<BZRStoreKitRequestsFactory> storeKitRequestsFactory;
__block BZRStoreKitFacade *storeKitFacade;

beforeEach(^{
  paymentQueueAdapter = OCMClassMock([BZRPaymentQueueAdapter class]);
  paymentQueueEventsSubject = [RACSubject subject];
  OCMStub([paymentQueueAdapter eventsSignal]).andReturn(paymentQueueEventsSubject);
  unfinishedTransactionsSubject = [RACSubject subject];
  OCMStub([paymentQueueAdapter unfinishedTransactionsSignal])
      .andReturn(unfinishedTransactionsSubject);

  purchaseManager = OCMClassMock([BZRPurchaseManager class]);
  unhandledTransactionsSubject = [RACSubject subject];
  OCMStub([purchaseManager unhandledTransactionsSignal]).andReturn(unhandledTransactionsSubject);

  restorationManager = OCMClassMock([BZRTransactionRestorationManager class]);
  downloadManager = OCMClassMock([BZRProductDownloadManager class]);
  storeKitRequestsFactory = OCMProtocolMock(@protocol(BZRStoreKitRequestsFactory));
  storeKitFacade =
      [[BZRStoreKitFacade alloc] initWithPaymentQueueAdapter:paymentQueueAdapter
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

  it(@"should send value response sent by payments request", ^{
    SKProduct *product = OCMClassMock([SKProduct class]);
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[product]);
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal return:response]);

    LLSignalTestRecorder *recorder =
        [[storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[response]);
  });

  it(@"should not cancel when signal completes", ^{
    SKProduct *product = OCMClassMock([SKProduct class]);
    SKProductsResponse *response = OCMClassMock([SKProductsResponse class]);
    OCMStub([response products]).andReturn(@[product]);
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal return:response]);
    OCMReject([productsRequest cancel]);

    auto signal = [storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers];

    expect(signal).will.complete();
  });

  it(@"should send error sent by products request", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal error:error]);

    RACSignal *signal = [storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers];

    expect(signal).will.sendError(error);
  });

  it(@"should not cancel when signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal error:error]);
    OCMReject([productsRequest cancel]);

    RACSignal *signal = [storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers];

    expect(signal).will.sendError(error);
  });

  it(@"should start when signal is subscribed to", ^{
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal never]);
    [[storeKitFacade fetchMetadataForProductsWithIdentifiers:productIdentifiers]
        subscribeNext:^(id) {}];

    OCMVerify([productsRequest start]);
  });

  it(@"should cancel when signal is disposed", ^{
    OCMStub([productsRequest statusSignal]).andReturn([RACSignal never]);
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
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal empty]);

    auto signal = [storeKitFacade refreshReceipt];

    expect(signal).will.complete();
  });

  it(@"should not cancel when signal completes", ^{
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal empty]);
    OCMReject([refreshRequest cancel]);

    auto signal = [storeKitFacade refreshReceipt];

    expect(signal).will.complete();
  });

  it(@"should send error sent by receipt refresh request", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal error:error]);

    RACSignal *signal = [storeKitFacade refreshReceipt];

    expect(signal).will.sendError(error);
  });

  it(@"should not cancel when signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal error:error]);
    OCMReject([refreshRequest cancel]);

    auto signal = [storeKitFacade refreshReceipt];

    expect(signal).will.sendError(error);
  });

  it(@"should start when singal is subscribed to", ^{
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal never]);
    [[storeKitFacade refreshReceipt] subscribeNext:^(id) {}];

    OCMVerify([refreshRequest start]);
  });

  it(@"should cancel when signal is disposed", ^{
    OCMStub([refreshRequest statusSignal]).andReturn([RACSignal never]);
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

    OCMVerify([paymentQueueAdapter finishTransaction:transaction]);
  });
});

context(@"sending unhandled transactions errors", ^{
  it(@"should complete when object is deallocated", ^{
    BZRStoreKitFacade * __weak weakStoreKitFacade;
    RACSignal *transactionsErrorEventsSignal;

    @autoreleasepool {
      BZRStoreKitFacade *storeKitFacade =
          [[BZRStoreKitFacade alloc] initWithPaymentQueueAdapter:paymentQueueAdapter
           purchaseManager:purchaseManager restorationManager:restorationManager
           downloadManager:downloadManager storeKitRequestsFactory:storeKitRequestsFactory];
      weakStoreKitFacade = storeKitFacade;

      transactionsErrorEventsSignal = storeKitFacade.transactionsErrorEventsSignal;
    }
    expect(weakStoreKitFacade).to.beNil();
    expect(transactionsErrorEventsSignal).will.complete();
  });

  it(@"should send error events for every unhandled transaction when purchase manager sends a list "
     "of unhandled transactions", ^{
    LLSignalTestRecorder *recorder = [storeKitFacade.transactionsErrorEventsSignal testRecorder];
    SKPaymentTransaction *firstTransaction = OCMClassMock([SKPaymentTransaction class]);
    SKPaymentTransaction *secondTransaction = OCMClassMock([SKPaymentTransaction class]);
    [unhandledTransactionsSubject sendNext:@[firstTransaction, secondTransaction]];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && error.lt_isLTDomain &&
          error.code == BZRErrorCodeUnhandledTransactionReceived &&
          error.bzr_transaction == firstTransaction;
    });
    expect(recorder).will.matchValue(1, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && error.lt_isLTDomain &&
          error.code == BZRErrorCodeUnhandledTransactionReceived &&
          error.bzr_transaction == secondTransaction;
    });
  });
});

context(@"handling unhandled transactions", ^{
  __block LLSignalTestRecorder *unhandledSuccessfulTransactionsSignal;

  beforeEach(^{
    unhandledSuccessfulTransactionsSignal =
        [storeKitFacade.unhandledSuccessfulTransactionsSignal testRecorder];
  });

  context(@"unfinished transactions", ^{
    context(@"purchasing transaction", ^{
      __block SKPaymentTransaction *transaction;

      beforeEach(^{
        transaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchasing);
      });

      it(@"should not finish transaction", ^{
        OCMReject([paymentQueueAdapter finishTransaction:OCMOCK_ANY]);

        [unfinishedTransactionsSubject sendNext:@[transaction]];
      });

      it(@"should not send transaction as successful", ^{
        [unfinishedTransactionsSubject sendNext:@[transaction]];

        expect(unhandledSuccessfulTransactionsSignal).will.sendValues(@[@[]]);
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

      it(@"should send an error event wrapping a failed transaction", ^{
        LLSignalTestRecorder *recorder =
            [storeKitFacade.transactionsErrorEventsSignal testRecorder];
        SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
        OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
        [unfinishedTransactionsSubject sendNext:@[transaction]];

        expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
          NSError *error = event.eventError;
          return [event.eventType isEqual:$(BZREventTypeCriticalError)] && error.lt_isLTDomain &&
              error.code == BZRErrorCodePurchaseFailed && error.bzr_transaction == transaction;
        });
      });

      it(@"should not send transaction as successful", ^{
        [unfinishedTransactionsSubject sendNext:@[transaction]];

        expect(unhandledSuccessfulTransactionsSignal).will.sendValues(@[@[]]);
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

        expect(unhandledSuccessfulTransactionsSignal).will.sendValues(@[@[transaction]]);
      });
    });
  });

  it(@"should send unhandled purchased transactions", ^{
    SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    [unfinishedTransactionsSubject sendNext:@[transaction]];

    expect(unhandledSuccessfulTransactionsSignal).will.sendValues(@[@[transaction]]);
  });

  it(@"should not send unhandled purchased transactions", ^{
    BZRStoreKitFacade * __weak weakStoreKitFacade;

    @autoreleasepool {
      BZRStoreKitFacade *storeKitFacade =
          [[BZRStoreKitFacade alloc] initWithPaymentQueueAdapter:paymentQueueAdapter
           purchaseManager:purchaseManager restorationManager:restorationManager
           downloadManager:downloadManager storeKitRequestsFactory:storeKitRequestsFactory];
      weakStoreKitFacade = storeKitFacade;

      SKPaymentTransaction *transaction = OCMClassMock([SKPaymentTransaction class]);
      OCMStub([transaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
      [unfinishedTransactionsSubject sendNext:@[transaction]];

      unhandledSuccessfulTransactionsSignal =
          [storeKitFacade.unhandledSuccessfulTransactionsSignal testRecorder];
    }

    expect(weakStoreKitFacade).to.beNil();
    expect(unhandledSuccessfulTransactionsSignal).will.complete();
    expect(unhandledSuccessfulTransactionsSignal).will.sendValuesWithCount(0);
  });
});

context(@"events signal", ^{
  it(@"should send event sent by payment queue's events signal", ^{
    auto event = [[BZREvent alloc] initWithType:$(BZREventTypeInformational) eventInfo:@{}];
    auto recorder = [storeKitFacade.eventsSignal testRecorder];

    [paymentQueueEventsSubject sendNext:event];

    expect(recorder).to.sendValues(@[event]);
  });
});

SpecEnd
