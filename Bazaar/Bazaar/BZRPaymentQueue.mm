// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueue.h"

#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@interface BZRPaymentQueue () <SKPaymentTransactionObserver>

/// Queue used to make payments, restore completed transactions and manage downloads.
@property (readonly, nonatomic) SKPaymentQueue *underlyingPaymentQueue;

/// Subject used to send unfinished transactions with.
@property (readonly, nonatomic) RACSubject *unfinishedTransactionsSubject;

/// if \c YES, transactions will be sent using \c unfinishedTransactionsSubject. Otherwise, they
/// will be passed to the appropriate delegate.
@property (nonatomic) BOOL shouldSendTransactionsAsUnfinished;

@end

/// Collection of transactions classified as payment transactions or restoration transactions.
typedef NSDictionary<NSString *, NSArray<SKPaymentTransaction *> *> BZRClassifiedTransactions;

@implementation BZRPaymentQueue

@synthesize downloadsDelegate = _downloadsDelegate;
@synthesize paymentsDelegate = _paymentsDelegate;
@synthesize restorationDelegate = _restorationDelegate;

/// Label for transactions classified as payment transactions.
static NSString * const kPaymentLabel = @"Payment";

/// Label for transactions classified as restoration transactions.
static NSString * const kRestorationLabel = @"Restoration";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)init {
  return [self initWithUnderlyingPaymentQueue:[SKPaymentQueue defaultQueue]
                unfinishedTransactionsSubject:nil];
}

- (instancetype)initWithUnfinishedTransactionsSubject:(nullable RACSubject *)
    unfinishedTransactionsSubject {
  return [self initWithUnderlyingPaymentQueue:[SKPaymentQueue defaultQueue]
                unfinishedTransactionsSubject:unfinishedTransactionsSubject];
}

- (instancetype)initWithUnderlyingPaymentQueue:(SKPaymentQueue *)underlyingPaymentQueue
    unfinishedTransactionsSubject:(nullable RACSubject *)unfinishedTransactionsSubject {
  if (self = [super init]) {
    _underlyingPaymentQueue = underlyingPaymentQueue;
    _unfinishedTransactionsSubject = unfinishedTransactionsSubject;
    [self.underlyingPaymentQueue addTransactionObserver:self];
    self.shouldSendTransactionsAsUnfinished = YES;
  }
  return self;
}

- (void)dealloc {
  [self.underlyingPaymentQueue removeTransactionObserver:self];
}

#pragma mark -
#pragma mark BZRDownloadsPaymentQueue
#pragma mark -

- (void)startDownloads:(NSArray<SKDownload *> *)downloads {
  [self.underlyingPaymentQueue startDownloads:downloads];
}

- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads {
  [self.underlyingPaymentQueue cancelDownloads:downloads];
}

- (NSArray<SKPaymentTransaction *> *)transactions {
  return self.underlyingPaymentQueue.transactions;
}

#pragma mark -
#pragma mark BZRPaymentsPaymentQueue
#pragma mark -

- (void)addPayment:(SKPayment *)payment {
  self.shouldSendTransactionsAsUnfinished = NO;
  [self.underlyingPaymentQueue addPayment:payment];
}

#pragma mark -
#pragma mark BZRRestorationPaymentQueue
#pragma mark -

- (void)restoreCompletedTransactions {
  self.shouldSendTransactionsAsUnfinished = NO;
  [self.underlyingPaymentQueue restoreCompletedTransactions];
}

- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username {
  self.shouldSendTransactionsAsUnfinished = NO;
  [self.underlyingPaymentQueue restoreCompletedTransactionsWithApplicationUsername:username];
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
  if (self.shouldSendTransactionsAsUnfinished) {
    [self sendTransactionsAsUnfinished:transactions];
    return;
  }

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

- (void)sendTransactionsAsUnfinished:(NSArray<SKPaymentTransaction *> *)transactions {
  for (SKPaymentTransaction *transaction in transactions) {
    [self.unfinishedTransactionsSubject sendNext:transaction];
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

#pragma mark -
#pragma mark Finishing transactions
#pragma mark -

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
  [self.underlyingPaymentQueue finishTransaction:transaction];
}

@end

NS_ASSUME_NONNULL_END
