// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueue.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZRPaymentQueue () <SKPaymentTransactionObserver>

/// Queue used to make payments, restore completed transactions and manage downloads.
@property (readonly, nonatomic) SKPaymentQueue *underlyingPaymentQueue;

@end

/// Collection of transactions classified as payment transactions or restoration transactions.
typedef NSDictionary<NSString *, NSArray<SKPaymentTransaction *> *> BZRClassifiedTransactions;

@implementation BZRPaymentQueue

/// Label for transactions classified as payment transactions.
static NSString * const kPaymentLabel = @"Payment";

/// Label for transactions classified as restoration transactions.
static NSString * const kRestorationLabel = @"Restoration";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithUnderlyingPaymentQueue:[SKPaymentQueue defaultQueue]];
}

- (instancetype)initWithUnderlyingPaymentQueue:(SKPaymentQueue *)underlyingPaymentQueue {
  if (self = [super init]) {
    _underlyingPaymentQueue = underlyingPaymentQueue;
    [self.underlyingPaymentQueue addTransactionObserver:self];
  }
  return self;
}

- (void)dealloc {
  [self.underlyingPaymentQueue removeTransactionObserver:self];
}

#pragma mark -
#pragma mark BZRPaymentQueue
#pragma mark -

- (void)addPayment:(SKPayment *)payment {
  [self.underlyingPaymentQueue addPayment:payment];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
  [self.underlyingPaymentQueue finishTransaction:transaction];
}

- (void)restoreCompletedTransactions {
  [self.underlyingPaymentQueue restoreCompletedTransactions];
}

- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username {
  [self.underlyingPaymentQueue restoreCompletedTransactionsWithApplicationUsername:username];
}

- (NSArray<SKPaymentTransaction *> *)transactions {
  return self.underlyingPaymentQueue.transactions;
}

- (void)startDownloads:(NSArray<SKDownload *> *)downloads {
  [self.underlyingPaymentQueue startDownloads:downloads];
}

- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads {
  [self.underlyingPaymentQueue cancelDownloads:downloads];
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver
#pragma mark -

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

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
 updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
  BZRClassifiedTransactions *classifiedTransactions =
      [[self class] classifyTransactions:transactions];

  if (classifiedTransactions[kPaymentLabel].count) {
    [self.paymentsDelegate paymentQueue:self
             paymentTransactionsUpdated:classifiedTransactions[kPaymentLabel]];
  }

  if (classifiedTransactions[kRestorationLabel].count) {
    [self.restorationDelegate paymentQueue:self
                      transactionsRestored:classifiedTransactions[kRestorationLabel]];
  }
}

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
 removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
  BZRClassifiedTransactions *classifiedTransactions =
      [[self class] classifyTransactions:transactions];

  if (classifiedTransactions[kPaymentLabel].count &&
      [self.paymentsDelegate
       respondsToSelector:@selector(paymentQueue:paymentTransactionsRemoved:)]) {
    [self.paymentsDelegate paymentQueue:self
             paymentTransactionsRemoved:classifiedTransactions[kPaymentLabel]];
  }

  if (classifiedTransactions[kRestorationLabel].count &&
      [self.restorationDelegate
       respondsToSelector:@selector(paymentQueue:restoredTransactionsRemoved:)]) {
    [self.restorationDelegate paymentQueue:self
               restoredTransactionsRemoved:classifiedTransactions[kRestorationLabel]];
  }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue __unused *)queue {
  [self.restorationDelegate paymentQueueRestorationCompleted:self];
}

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
    restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [self.restorationDelegate paymentQueue:self restorationFailedWithError:error];
}

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
    updatedDownloads:(NSArray<SKDownload *> *)downloads {
  [self.downloadsDelegate paymentQueue:self updatedDownloads:downloads];
}

@end

NS_ASSUME_NONNULL_END
