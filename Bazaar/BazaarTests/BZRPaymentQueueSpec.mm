// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueue.h"

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

@interface BZRPaymentQueue () <SKPaymentTransactionObserver>
@end

SpecBegin(BZRPaymentQueue)

__block SKPaymentQueue *underlyingPaymentQueue;
__block RACSubject *subject;
__block id paymentsDelegate;
__block id restorationDelegate;
__block id downloadsDelegate;
__block BZRPaymentQueue *paymentQueue;

beforeEach(^{
  underlyingPaymentQueue = OCMClassMock([SKPaymentQueue class]);
  subject = [RACSubject subject];
  paymentsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueuePaymentsDelegate));
  restorationDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueRestorationDelegate));
  downloadsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueDownloadsDelegate));

  paymentQueue = [[BZRPaymentQueue alloc] initWithUnderlyingPaymentQueue:underlyingPaymentQueue
                                           unfinishedTransactionsSubject:subject];
  paymentQueue.paymentsDelegate = paymentsDelegate;
  paymentQueue.restorationDelegate = restorationDelegate;
  paymentQueue.downloadsDelegate = downloadsDelegate;
});

context(@"deallocating object", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRPaymentQueue __weak *weakPaymentQueue;
    @autoreleasepool {
      BZRPaymentQueue *paymentQueue = [[BZRPaymentQueue alloc] init];
      weakPaymentQueue = paymentQueue;
    }
    expect(weakPaymentQueue).to.beNil();
  });
});

context(@"transactions", ^{
  __block NSArray<SKPaymentTransaction *> *paymentTransactions;
  __block NSArray<SKPaymentTransaction *> *restorationTransactions;

  beforeEach(^{
    SKPaymentTransaction *purchasingTransaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([purchasingTransaction transactionState])
        .andReturn(SKPaymentTransactionStatePurchasing);
    SKPaymentTransaction *deferredTransaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([deferredTransaction transactionState]).andReturn(SKPaymentTransactionStateDeferred);
    SKPaymentTransaction *failedTransaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([failedTransaction transactionState]).andReturn(SKPaymentTransactionStateFailed);
    SKPaymentTransaction *purchasedTransaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([purchasedTransaction transactionState]).andReturn(SKPaymentTransactionStatePurchased);
    SKPaymentTransaction *restoredTransaction = OCMClassMock([SKPaymentTransaction class]);
    OCMStub([restoredTransaction transactionState]).andReturn(SKPaymentTransactionStateRestored);

    paymentTransactions = @[
      purchasingTransaction,
      deferredTransaction,
      failedTransaction,
      purchasedTransaction
    ];
    restorationTransactions = @[restoredTransaction, restoredTransaction];
  });

  context(@"sending transactions to right place", ^{
    it(@"should send transactions with subject and not call delegate", ^{
      OCMReject([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:paymentTransactions]);
      LLSignalTestRecorder *recorder = [subject testRecorder];

      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:paymentTransactions];

      expect(recorder).will.sendValues(paymentTransactions);
    });

    it(@"should send transactions to delegates if restore completed transactions was called", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:paymentTransactions]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                             transactionsRestored:restorationTransactions]);
      LLSignalTestRecorder *recorder = [subject testRecorder];

      [paymentQueue restoreCompletedTransactions];
      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:paymentTransactions];
      [subject sendCompleted];

      expect(recorder).will.complete();
      expect(recorder).will.sendValuesWithCount(0);
    });

    it(@"should send transactions to delegates if restore completed transactions with username was "
       "called", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:paymentTransactions]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                             transactionsRestored:restorationTransactions]);
      LLSignalTestRecorder *recorder = [subject testRecorder];

      [paymentQueue restoreCompletedTransactionsWithApplicationUsername:@"foo"];
      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:paymentTransactions];
      [subject sendCompleted];

      expect(recorder).will.complete();
      expect(recorder).will.sendValuesWithCount(0);
    });

    it(@"should send transactions to delegates if add payment was called", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:paymentTransactions]);
      LLSignalTestRecorder *recorder = [subject testRecorder];

      [paymentQueue addPayment:OCMClassMock([SKPayment class])];
      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:paymentTransactions];
      [subject sendCompleted];

      expect(recorder).will.complete();
      expect(recorder).will.sendValuesWithCount(0);
    });
  });

  context(@"sending transactions to delegates", ^{
    beforeEach(^{
      [paymentQueue addPayment:OCMClassMock([SKPayment class])];
    });

    it(@"should notify payments delegate when payment transactions are updated", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:paymentTransactions]);

      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:paymentTransactions];
      OCMVerifyAll(paymentsDelegate);
    });

    it(@"should notify restoration delegate when restoration transactions are updated", ^{
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                             transactionsRestored:restorationTransactions]);

      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:restorationTransactions];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should correctly separate transaction updates to payment and restoration delegates", ^{
      NSArray *transactions = BZRZipArrays(paymentTransactions, restorationTransactions);
      NSRange range = NSMakeRange(0, transactions.count / 2);
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsUpdated:[paymentTransactions subarrayWithRange:range]]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                             transactionsRestored:[restorationTransactions subarrayWithRange:range]]);

      [paymentQueue paymentQueue:underlyingPaymentQueue updatedTransactions:transactions];
      OCMVerifyAll(paymentsDelegate);
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify payments delegate when payment transactions are removed", ^{
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsRemoved:paymentTransactions]);

      [paymentQueue paymentQueue:underlyingPaymentQueue removedTransactions:paymentTransactions];
      OCMVerifyAll(paymentsDelegate);
    });

    it(@"should notify restoration delegate when restoration transactions are removed", ^{
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                      restoredTransactionsRemoved:restorationTransactions]);

      [paymentQueue paymentQueue:underlyingPaymentQueue removedTransactions:restorationTransactions];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should correctly separate removed transactions to payment and restoration delegates", ^{
      NSArray *transactions = BZRZipArrays(paymentTransactions, restorationTransactions);
      NSRange range = NSMakeRange(0, transactions.count / 2);
      OCMExpect([paymentsDelegate paymentQueue:paymentQueue
                    paymentTransactionsRemoved:[paymentTransactions subarrayWithRange:range]]);
      OCMExpect([restorationDelegate paymentQueue:paymentQueue
                      restoredTransactionsRemoved:[restorationTransactions subarrayWithRange:range]]);

      [paymentQueue paymentQueue:underlyingPaymentQueue removedTransactions:transactions];
      OCMVerifyAll(paymentsDelegate);
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify the restoration delegate when restoration completes", ^{
      OCMExpect([restorationDelegate paymentQueueRestorationCompleted:paymentQueue]);

      [paymentQueue paymentQueueRestoreCompletedTransactionsFinished:underlyingPaymentQueue];
      OCMVerifyAll(restorationDelegate);
    });

    it(@"should notify the restoration delegate when restoration fails", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      OCMExpect([restorationDelegate paymentQueue:paymentQueue restorationFailedWithError:error]);

      [paymentQueue paymentQueue:underlyingPaymentQueue
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
    OCMExpect([downloadsDelegate paymentQueue:paymentQueue updatedDownloads:downloads]);

    [paymentQueue paymentQueue:underlyingPaymentQueue updatedDownloads:downloads];
    OCMVerifyAll(downloadsDelegate);
  });
});

SpecEnd
