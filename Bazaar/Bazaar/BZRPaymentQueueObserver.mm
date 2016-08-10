// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueueObserver.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BZRPaymentQueueObserver

/// Label for transactions classified as payment transactions.
static NSString * const kPaymentLabel = @"Payment";

/// Label for transactions classified as restoration transactions.
static NSString * const kRestorationLabel = @"Restoration";

/// Collection of transactions classified as payment transactions or restoration transactions.
typedef NSDictionary<NSString *, NSArray<SKPaymentTransaction *> *> BZRClassifiedTransactions;

// Classifies a given array of \c transactions and splits them into 2 classes: payment transactions
// and restoration transactions.
//
// The method returns a classifed dictionary with 2 entries: one entry with key set to
// \c kPaymentLabel and its value is an array of payment transactions and the the other entry has
// its key set to \c kRestorationLabel and its value is an array of restoration transactions.
+ (BZRClassifiedTransactions *)classifyTransactions:
    (NSArray<SKPaymentTransaction *> *)transactions {
  return (BZRClassifiedTransactions *)
      [transactions lt_classify:^NSString *(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStateRestored ?
            kRestorationLabel : kPaymentLabel;
      }];
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
  BZRClassifiedTransactions *classifiedTransactions =
      [[self class] classifyTransactions:transactions];

  if (classifiedTransactions[kPaymentLabel].count) {
    [self.paymentsDelegate paymentQueue:queue
             paymentTransactionsUpdated:classifiedTransactions[kPaymentLabel]];
  }

  if (classifiedTransactions[kRestorationLabel].count) {
    [self.restorationDelegate paymentQueue:queue
                      transactionsRestored:classifiedTransactions[kRestorationLabel]];
  }
}

- (void)paymentQueue:(SKPaymentQueue *)queue
 removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
  BZRClassifiedTransactions *classifiedTransactions =
      [[self class] classifyTransactions:transactions];

  if (classifiedTransactions[kPaymentLabel].count &&
      [self.paymentsDelegate
       respondsToSelector:@selector(paymentQueue:paymentTransactionsRemoved:)]) {
    [self.paymentsDelegate paymentQueue:queue
             paymentTransactionsRemoved:classifiedTransactions[kPaymentLabel]];
  }

  if (classifiedTransactions[kRestorationLabel].count &&
      [self.restorationDelegate
       respondsToSelector:@selector(paymentQueue:restoredTransactionsRemoved:)]) {
    [self.restorationDelegate paymentQueue:queue
               restoredTransactionsRemoved:classifiedTransactions[kRestorationLabel]];
  }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
  [self.restorationDelegate paymentQueueRestorationCompleted:queue];
}

- (void)paymentQueue:(SKPaymentQueue *)queue
    restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [self.restorationDelegate paymentQueue:queue restorationFailedWithError:error];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
  [self.downloadsDelegate paymentQueue:queue updatedDownloads:downloads];
}

@end

NS_ASSUME_NONNULL_END
