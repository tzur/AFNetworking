// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRPaymentQueueAdapter.h"

#import <LTKit/NSArray+Functional.h>

#import "BZREvent+AdditionalInfo.h"
#import "BZRPaymentQueue.h"
#import "SKPaymentTransaction+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPaymentQueueAdapter () <SKPaymentTransactionObserver>

/// Queue used to make payments, restore completed transactions and manage downloads.
@property (readonly, nonatomic) id<BZRPaymentQueue> underlyingPaymentQueue;

/// Subject used to send an array of unfinished transactions.
@property (readonly, nonatomic) RACSubject<BZRPaymentTransactionList *> *
  unfinishedTransactionsSubject;

/// if \c YES, transactions will be sent using \c unfinishedTransactionsSubject. Otherwise, they
/// will be passed to the appropriate delegate.
@property (nonatomic) BOOL shouldSendTransactionsAsUnfinished;

/// Subject used to send events with.
@property (readonly, nonatomic) RACReplaySubject<BZREvent *> *eventsSubject;

@end

/// Collection of transactions classified as payment transactions or restoration transactions.
typedef NSDictionary<NSString *, BZRPaymentTransactionList *> BZRClassifiedTransactions;

@implementation BZRPaymentQueueAdapter

@synthesize downloadsDelegate = _downloadsDelegate;
@synthesize paymentsDelegate = _paymentsDelegate;
@synthesize restorationDelegate = _restorationDelegate;
@synthesize eventsSignal = _eventsSignal;

/// Label for transactions classified as payment transactions.
static NSString * const kPaymentLabel = @"Payment";

/// Label for transactions classified as restoration transactions.
static NSString * const kRestorationLabel = @"Restoration";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithPaymentQueue:(id<BZRPaymentQueue>)underlyingPaymentQueue {
  if (self = [super init]) {
    _underlyingPaymentQueue = underlyingPaymentQueue;
    _unfinishedTransactionsSubject = [RACSubject subject];
    _unfinishedTransactionsSignal =
        [[self.unfinishedTransactionsSubject replay] takeUntil:[self rac_willDeallocSignal]];
    _eventsSubject = [RACReplaySubject subject];
    _eventsSignal = [self.eventsSubject takeUntil:[self rac_willDeallocSignal]];
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

- (void)restoreCompletedTransactionsWithApplicationUserID:(nullable NSString *)applicationUserID {
  self.shouldSendTransactionsAsUnfinished = NO;
  [self.underlyingPaymentQueue
   restoreCompletedTransactionsWithApplicationUsername:applicationUserID];
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
    (BZRPaymentTransactionList *)transactions {
  return (BZRClassifiedTransactions *)
      [transactions lt_classify:^NSString *(SKPaymentTransaction *transaction) {
        return transaction.transactionState == SKPaymentTransactionStateRestored ?
            kRestorationLabel : kPaymentLabel;
      }];
}

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
 updatedTransactions:(BZRPaymentTransactionList *)transactions {
  [self sendTransactionsEvents:transactions removedTransactions:NO];

  if (self.shouldSendTransactionsAsUnfinished) {
    [self.unfinishedTransactionsSubject sendNext:transactions];
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

- (void)paymentQueue:(SKPaymentQueue __unused *)queue
 removedTransactions:(BZRPaymentTransactionList *)transactions {
  [self sendTransactionsEvents:transactions removedTransactions:YES];
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

- (void)sendTransactionsEvents:(BZRPaymentTransactionList *)transactions
           removedTransactions:(BOOL)removedTransactions {
  for (SKPaymentTransaction *transaction in transactions) {
    [self.eventsSubject sendNext:
     [BZREvent transactionReceivedEvent:transaction removedTransaction:removedTransactions]];
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

#pragma mark -
#pragma mark Promoted IAP
#pragma mark -

- (BOOL)paymentQueue:(SKPaymentQueue __unused *)queue shouldAddStorePayment:(SKPayment *)payment
          forProduct:(SKProduct *)product {
  BOOL shouldProceedWithPurchase =
      [self.paymentsDelegate shouldProceedWithPromotedIAP:product payment:payment];
  auto event = [[BZREvent alloc] initWithType:$(BZREventTypePromotedIAPInitiated)
      eventInfo:@{
        kBZREventProductIdentifier: product.productIdentifier,
        kBZREventPromotedIAPAborted: @(!shouldProceedWithPurchase)
      }];
  [self.eventsSubject sendNext:event];
  return shouldProceedWithPurchase;
}

@end

NS_ASSUME_NONNULL_END
