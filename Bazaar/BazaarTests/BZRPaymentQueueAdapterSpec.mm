// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueueAdapter.h"

#import "BZREvent+AdditionalInfo.h"
#import "BZRPaymentQueue.h"
#import "BZRTestUtils.h"
#import "SKPaymentTransaction+Bazaar.h"

/// Fake \c BZRInternalPaymentQueue.
@interface BZRFakeInternalPaymentQueue : NSObject <BZRPaymentQueue>
@end

@implementation BZRFakeInternalPaymentQueue

@synthesize transactions = _transactions;

- (void)addPayment:(SKPayment * __unused)payment {
}

- (void)restoreCompletedTransactions {
}

- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString * __unused)username {
}

- (void)finishTransaction:(SKPaymentTransaction * __unused)transaction {
}

- (void)startDownloads:(NSArray<SKDownload *> * __unused)downloads {
}

- (void)pauseDownloads:(NSArray<SKDownload *> * __unused)downloads {
}

- (void)resumeDownloads:(NSArray<SKDownload *> * __unused)downloads {
}

- (void)cancelDownloads:(NSArray<SKDownload *> * __unused)downloads {
}

- (void)addTransactionObserver:(id<SKPaymentTransactionObserver> __unused)observer {
}

- (void)removeTransactionObserver:(id<SKPaymentTransactionObserver> __unused)observer {
}

@end

/// Returns a new array which contains interleaved objects from \c anArray and \c anotherArray.
/// Item at index \c i in the returned array is the <tt>(i / 2)</tt>'th item from \c anArray if
/// <tt>i % 2 == 0</tt> or from \c anotherArray if <tt>i % 2 == 1</tt>. The length of the new array
/// will be <tt>2 * min(anArray.count, anotherArray.count)</tt>.
NSArray *BZRZipArrays(NSArray *anArray, NSArray *anotherArray) {
  NSMutableArray<SKPaymentTransaction *> *zippedArray = [NSMutableArray array];
  NSUInteger count = std::min(anArray.count, anotherArray.count);
  for (NSUInteger i = 0; i < count; ++i) {
    [zippedArray addObject:anArray[i]];
    [zippedArray addObject:anotherArray[i]];
  }
  return zippedArray;
}

@interface BZRPaymentQueueAdapter () <SKPaymentTransactionObserver>
@end

SpecBegin(BZRPaymentQueue)

__block id<BZRPaymentQueue> underlyingPaymentQueue;
__block id paymentsDelegate;
__block id restorationDelegate;
__block id downloadsDelegate;
__block BZRPaymentQueueAdapter *paymentQueueAdapter;

beforeEach(^{
  underlyingPaymentQueue = [[BZRFakeInternalPaymentQueue alloc] init];
  paymentsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueuePaymentsDelegate));
  restorationDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueRestorationDelegate));
  downloadsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueDownloadsDelegate));

  paymentQueueAdapter =
      [[BZRPaymentQueueAdapter alloc] initWithPaymentQueue:underlyingPaymentQueue];
  paymentQueueAdapter.paymentsDelegate = paymentsDelegate;
  paymentQueueAdapter.restorationDelegate = restorationDelegate;
  paymentQueueAdapter.downloadsDelegate = downloadsDelegate;
});

context(@"deallocating object", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRPaymentQueueAdapter __weak *weakPaymentQueueAdapter;

    @autoreleasepool {
      BZRPaymentQueueAdapter *paymentQueueAdapter =
          [[BZRPaymentQueueAdapter alloc] initWithPaymentQueue:underlyingPaymentQueue];
      weakPaymentQueueAdapter = paymentQueueAdapter;
    }

    expect(weakPaymentQueueAdapter).to.beNil();
  });
});

context(@"transactions", ^{
  __block NSArray<SKPaymentTransaction *> *paymentTransactions;
  __block NSArray<SKPaymentTransaction *> *restorationTransactions;

  beforeEach(^{
    SKPaymentTransaction *purchasingTransaction =
        BZRMockedSKPaymentTransaction(@"foo", @"bar", SKPaymentTransactionStatePurchasing);
    OCMStub([purchasingTransaction transactionStateString])
        .andReturn(@"SKPaymentTransactionStatePurchasing");
    SKPaymentTransaction *deferredTransaction =
        BZRMockedSKPaymentTransaction(@"foo", @"bar", SKPaymentTransactionStateDeferred);
    OCMStub([deferredTransaction transactionStateString])
        .andReturn(@"SKPaymentTransactionStateDeferred");
    SKPaymentTransaction *failedTransaction =
        BZRMockedSKPaymentTransaction(@"foo", @"bar", SKPaymentTransactionStateFailed);
    OCMStub([failedTransaction transactionStateString])
        .andReturn(@"SKPaymentTransactionStateFailed");
    SKPaymentTransaction *purchasedTransaction =
        BZRMockedSKPaymentTransaction(@"foo", @"bar", SKPaymentTransactionStatePurchased);
    OCMStub([purchasedTransaction transactionStateString])
        .andReturn(@"SKPaymentTransactionStatePurchased");
    SKPaymentTransaction *restoredTransaction =
        BZRMockedSKPaymentTransaction(@"foo", @"bar", SKPaymentTransactionStateRestored);
    OCMStub([restoredTransaction transactionStateString])
        .andReturn(@"SKPaymentTransactionStateRestored");

    paymentTransactions = @[
      purchasingTransaction,
      deferredTransaction,
      failedTransaction,
      purchasedTransaction
    ];
    restorationTransactions = @[restoredTransaction, restoredTransaction];
  });

  context(@"sending transactions to right place", ^{
    it(@"should send transactions through signal and not call delegate", ^{
      OCMReject([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsUpdated:paymentTransactions]);
      LLSignalTestRecorder *recorder =
          [paymentQueueAdapter.unfinishedTransactionsSignal testRecorder];

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                    updatedTransactions:paymentTransactions];

      expect(recorder).will.sendValues(@[paymentTransactions]);
    });

    it(@"should send transactions when new subscriber subscribes", ^{
      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                    updatedTransactions:paymentTransactions];

      LLSignalTestRecorder *recorder =
          [paymentQueueAdapter.unfinishedTransactionsSignal testRecorder];

      expect(recorder).will.sendValues(@[paymentTransactions]);
    });

    it(@"should send transactions to delegates if restore completed transactions with username was "
       "called", ^{
      BZRPaymentQueueAdapter * __weak weakPaymentQueue;
      LLSignalTestRecorder *recorder;
      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsUpdated:paymentTransactions]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                             transactionsRestored:restorationTransactions]);

      @autoreleasepool {
        BZRPaymentQueueAdapter *paymentQueueAdapter =
            [[BZRPaymentQueueAdapter alloc] initWithPaymentQueue:underlyingPaymentQueue];
        weakPaymentQueue = paymentQueueAdapter;
        recorder = [weakPaymentQueue.unfinishedTransactionsSignal testRecorder];

        [paymentQueueAdapter restoreCompletedTransactionsWithApplicationUserID:@"foo"];
        [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                      updatedTransactions:paymentTransactions];
      }

      expect(recorder).will.complete();
      expect(recorder).to.sendValuesWithCount(0);
    });

    it(@"should send transactions to delegates if add payment was called", ^{
      BZRPaymentQueueAdapter * __weak weakPaymentQueue;
      LLSignalTestRecorder *recorder;
      SKPayment *payment = OCMClassMock([SKPayment class]);
      OCMStub([payment productIdentifier]).andReturn(@"foo");
      OCMStub([payment quantity]).andReturn(1);

      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsUpdated:paymentTransactions]);

      @autoreleasepool {
        BZRPaymentQueueAdapter *paymentQueueAdapter =
            [[BZRPaymentQueueAdapter alloc] initWithPaymentQueue:underlyingPaymentQueue];
        weakPaymentQueue = paymentQueueAdapter;
        recorder = [weakPaymentQueue.unfinishedTransactionsSignal testRecorder];

        [paymentQueueAdapter addPayment:payment];
        [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                      updatedTransactions:paymentTransactions];
      }

      expect(recorder).will.complete();
      expect(recorder).to.sendValuesWithCount(0);
    });
  });

  context(@"sending transactions to delegates", ^{
    beforeEach(^{
      [paymentQueueAdapter addPayment:OCMClassMock([SKPayment class])];
    });

    it(@"should notify payments delegate when payment transactions are updated", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsUpdated:paymentTransactions]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                    updatedTransactions:paymentTransactions];
      OCMVerifyAll(paymentsDelegate);
    });

    it(@"should notify restoration delegate when restoration transactions are updated", ^{
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                             transactionsRestored:restorationTransactions]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
             updatedTransactions:restorationTransactions];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should correctly separate transaction updates to payment and restoration delegates", ^{
      NSArray *transactions = BZRZipArrays(paymentTransactions, restorationTransactions);
      NSRange range = NSMakeRange(0, transactions.count / 2);
      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsUpdated:[paymentTransactions subarrayWithRange:range]]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                             transactionsRestored:[restorationTransactions
                                                   subarrayWithRange:range]]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue updatedTransactions:transactions];
      OCMVerifyAll(paymentsDelegate);
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify payments delegate when payment transactions are removed", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsRemoved:paymentTransactions]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
                    removedTransactions:paymentTransactions];
      OCMVerifyAll(paymentsDelegate);
    });

    it(@"should notify restoration delegate when restoration transactions are removed", ^{
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                      restoredTransactionsRemoved:restorationTransactions]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
             removedTransactions:restorationTransactions];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should correctly separate removed transactions to payment and restoration delegates", ^{
      NSArray *transactions = BZRZipArrays(paymentTransactions, restorationTransactions);
      NSRange range = NSMakeRange(0, transactions.count / 2);
      OCMExpect([paymentsDelegate paymentQueue:paymentQueueAdapter
                    paymentTransactionsRemoved:[paymentTransactions subarrayWithRange:range]]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                      restoredTransactionsRemoved:[restorationTransactions
                                                   subarrayWithRange:range]]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue removedTransactions:transactions];
      OCMVerifyAll(paymentsDelegate);
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify the restoration delegate when restoration completes", ^{
      OCMExpect([restorationDelegate paymentQueueRestorationCompleted:paymentQueueAdapter]);

      [paymentQueueAdapter paymentQueueRestoreCompletedTransactionsFinished:underlyingPaymentQueue];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify the restoration delegate when restoration fails", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMExpect([restorationDelegate paymentQueue:paymentQueueAdapter
                       restorationFailedWithError:error]);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue
          restoreCompletedTransactionsFailedWithError:error];
      OCMVerifyAll(restorationDelegate);
    });
  });
});

context(@"downloads", ^{
  it(@"should report the downloads delegate when downloads are updated", ^{
    NSArray<SKDownload *> *downloads = @[
      OCMClassMock([SKDownload class]),
      OCMClassMock([SKDownload class])
    ];
    OCMExpect([downloadsDelegate paymentQueue:paymentQueueAdapter updatedDownloads:downloads]);

    [paymentQueueAdapter paymentQueue:underlyingPaymentQueue updatedDownloads:downloads];
    OCMVerifyAll(downloadsDelegate);
  });
});

if (@available(iOS 11.0, *)) {
  context(@"promoted IAP", ^{
    __block SKPayment *payment;
    __block SKProduct *product;

    beforeEach(^{
      payment = OCMClassMock([SKPayment class]);
      product = OCMClassMock([SKProduct class]);
      OCMStub([product productIdentifier]).andReturn(@"foo");
    });

    context(@"not proceeding with promoted IAP", ^{
      it(@"should return NO", ^{
        OCMStub([paymentsDelegate shouldProceedWithPromotedIAP:OCMOCK_ANY payment:OCMOCK_ANY])
            .andReturn(NO);

        BOOL shouldAddPayment =
            [paymentQueueAdapter paymentQueue:underlyingPaymentQueue shouldAddStorePayment:payment
                            forProduct:product];

        expect(shouldAddPayment).to.beFalsy();
      });

      it(@"should send event when promoted IAP is initiated", ^{
        OCMStub([paymentsDelegate shouldProceedWithPromotedIAP:OCMOCK_ANY payment:OCMOCK_ANY])
            .andReturn(NO);
        auto recorder = [paymentQueueAdapter.eventsSignal testRecorder];

        [paymentQueueAdapter paymentQueue:underlyingPaymentQueue shouldAddStorePayment:payment
                        forProduct:product];

        expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
          return [event.eventType isEqual:$(BZREventTypePromotedIAPInitiated)] &&
              [event.eventInfo[kBZREventProductIdentifierKey] isEqualToString:@"foo"] &&
              [event.eventInfo[kBZREventPromotedIAPAbortedKey] boolValue];
        });
      });
    });

    context(@"proceeding with promoted IAP", ^{
      it(@"should return YES", ^{
        OCMStub([paymentsDelegate shouldProceedWithPromotedIAP:OCMOCK_ANY payment:OCMOCK_ANY])
            .andReturn(YES);

        BOOL shouldAddPayment =
            [paymentQueueAdapter paymentQueue:underlyingPaymentQueue shouldAddStorePayment:payment
                            forProduct:product];

        expect(shouldAddPayment).to.beTruthy();
      });

      it(@"should send event when promoted IAP is initiated", ^{
        OCMStub([paymentsDelegate shouldProceedWithPromotedIAP:OCMOCK_ANY payment:OCMOCK_ANY])
            .andReturn(YES);
        auto recorder = [paymentQueueAdapter.eventsSignal testRecorder];

        [paymentQueueAdapter paymentQueue:underlyingPaymentQueue shouldAddStorePayment:payment
                        forProduct:product];

        expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
          return [event.eventType isEqual:$(BZREventTypePromotedIAPInitiated)] &&
              [event.eventInfo[kBZREventProductIdentifierKey] isEqualToString:@"foo"] &&
              ![event.eventInfo[kBZREventPromotedIAPAbortedKey] boolValue];
        });
      });

    it(@"should send events to late subscriber", ^{
      OCMStub([paymentsDelegate shouldProceedWithPromotedIAP:OCMOCK_ANY payment:OCMOCK_ANY])
          .andReturn(YES);

      [paymentQueueAdapter paymentQueue:underlyingPaymentQueue shouldAddStorePayment:payment
                      forProduct:product];

      expect(paymentQueueAdapter.eventsSignal).to.sendValuesWithCount(1);
      });
    });
  });
}

SpecEnd
