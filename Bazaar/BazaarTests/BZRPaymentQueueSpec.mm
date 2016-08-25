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
__block id paymentsDelegate;
__block id restorationDelegate;
__block id downloadsDelegate;
__block BZRPaymentQueue *paymentQueue;

beforeEach(^{
  underlyingPaymentQueue = OCMClassMock([SKPaymentQueue class]);
  paymentsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueuePaymentsDelegate));
  restorationDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueRestorationDelegate));
  downloadsDelegate = OCMStrictProtocolMock(@protocol(BZRPaymentQueueDownloadsDelegate));

  paymentQueue = [[BZRPaymentQueue alloc] initWithUnderlyingPaymentQueue:underlyingPaymentQueue];
  paymentQueue.paymentsDelegate = paymentsDelegate;
  paymentQueue.restorationDelegate = restorationDelegate;
  paymentQueue.downloadsDelegate = downloadsDelegate;
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
