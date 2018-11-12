// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchaseManager.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRPaymentsPaymentQueue.h"
#import "BZRPurchaseHelper.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

/// Associates a transaction with an \c SKPayment.
@interface SKPaymentTransaction (AssociatedPayment)

/// Payment associated with the transaction.
@property (strong, nonatomic, nullable) SKPayment *bzr_associatedPayment;

@end

@implementation SKPaymentTransaction (AssociatedPayment)

- (nullable SKPayment *)bzr_associatedPayment {
  return objc_getAssociatedObject(self, @selector(bzr_associatedPayment));
}

- (void)setBzr_associatedPayment:(nullable SKPayment *)payment {
  objc_setAssociatedObject(self, @selector(bzr_associatedPayment), payment,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface BZRPurchaseManager () <BZRPaymentQueuePaymentsDelegate>

/// Queue used to make purchases.
@property (readonly, nonatomic) id<BZRPaymentsPaymentQueue> paymentQueue;

/// Application user identifier to use in payments.
@property (readonly, nonatomic, nullable) NSString *applicationUserID;

/// Helper used to determine whether a purchase should be aborted.
@property (readonly, nonatomic) id<BZRPurchaseHelper> purchaseHelper;

/// Payments for which no transaction updates have arrived.
@property (readonly, nonatomic) NSMutableArray<SKPayment *> *pendingPayments;

/// Queue used for accessing \c pendingPayments.
@property (readonly, nonatomic) dispatch_queue_t paymentDataAccessQueue;

/// Sends transactions that are received from the delegate calls and are not associated with a
/// purchase made using the receiver.
@property (readonly, nonatomic) RACSubject<BZRPaymentTransactionList *> *
    unhandledTransactionsSubject;

@end

@implementation BZRPurchaseManager

#pragma mark -
#pragma mark Initialization and Destruction
#pragma mark -

- (instancetype)initWithPaymentQueue:(id<BZRPaymentsPaymentQueue>)paymentQueue
                   applicationUserID:(nullable NSString *)applicationUserID
                      purchaseHelper:(id<BZRPurchaseHelper>)purchaseHelper {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    self.paymentQueue.paymentsDelegate = self;
    _applicationUserID = [applicationUserID copy];
    _purchaseHelper = purchaseHelper;
    _pendingPayments = [[NSMutableArray alloc] init];
    _paymentDataAccessQueue =
        dispatch_queue_create("com.lightricks.bazaar.purchaseManager.dataAccessQueue",
                              DISPATCH_QUEUE_SERIAL);
    _unhandledTransactionsSubject = [RACSubject subject];
    _unhandledTransactionsSignal =
        [[self.unhandledTransactionsSubject replay] takeUntil:[self rac_willDeallocSignal]];
  }
  return self;
}

#pragma mark -
#pragma mark Purchasing
#pragma mark -

- (RACSignal<SKPaymentTransaction *> *)purchaseProduct:(SKProduct *)product
                                              quantity:(NSUInteger)quantity {
  @weakify(self);
  return [[[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = quantity;
        payment.applicationUsername = self.applicationUserID;
        auto disposable = [[self transactionUpdatesForPayment:payment] subscribe:subscriber];

        dispatch_sync(self.paymentDataAccessQueue, ^{
          [self.pendingPayments addObject:payment];
        });
        [self.paymentQueue addPayment:payment];

        return disposable;
      }]
      takeUntil:[self rac_willDeallocSignal]]
      setNameWithFormat:@"%@ -purchaseProduct:quantity:", self.description];
}

- (RACSignal<SKPaymentTransaction *> *)transactionUpdatesForPayment:(SKPayment *)payment {
  @weakify(self);
  return [[[[self rac_signalForSelector:@selector(receivedTransaction:transactionFinished:)]
      filter:^BOOL(RACTuple *tuple) {
        RACTupleUnpack(SKPaymentTransaction *transaction, NSNumber *transactionFinished) = tuple;
        /// Filter out transactions not associated with the payment and the update that inform
        /// about finishing the transaction in case the transaction failed. This filtering is
        /// required to avoid sending completion in case an error was previously sent.
        return (transaction.bzr_associatedPayment == payment) &&
            !([transactionFinished boolValue] &&
              transaction.transactionState == SKPaymentTransactionStateFailed);
      }]
      map:^RACEvent *(RACTuple *tuple) {
        @strongify(self);
        RACTupleUnpack(SKPaymentTransaction *transaction, NSNumber *transactionFinished) = tuple;
        if ([transactionFinished boolValue]) {
          return [RACEvent completedEvent];
        } else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
          return [RACEvent eventWithError:[self failedTransactionError:transaction]];
        }
        return [RACEvent eventWithValue:transaction];
      }]
      dematerialize];
}

- (NSError *)failedTransactionError:(SKPaymentTransaction *)transaction {
  if ([transaction.error.domain isEqualToString:SKErrorDomain]) {
    if (transaction.error.code == SKErrorPaymentCancelled) {
      return [NSError bzr_errorWithCode:BZRErrorCodeOperationCancelled transaction:transaction];
    } else if (transaction.error.code == SKErrorPaymentNotAllowed) {
      return [NSError bzr_errorWithCode:BZRErrorCodePurchaseNotAllowed transaction:transaction];
    }
  }

  return [NSError bzr_errorWithCode:BZRErrorCodePurchaseFailed transaction:transaction];
}

#pragma mark -
#pragma mark BZRPaymentQueuePaymentsDelegate
#pragma mark -

- (void)paymentQueue:(SKPaymentQueue __unused *)paymentQueue
    paymentTransactionsUpdated:(BZRPaymentTransactionList *)transactions {
  [self handleTransactions:transactions transactionsFinished:NO];
}

- (void)paymentQueue:(SKPaymentQueue __unused *)paymentQueue
    paymentTransactionsRemoved:(BZRPaymentTransactionList *)transactions {
  [self handleTransactions:transactions transactionsFinished:YES];
}

#pragma mark -
#pragma mark Handling Transaction Updates
#pragma mark -

- (void)handleTransactions:(BZRPaymentTransactionList *)transactions
      transactionsFinished:(BOOL)transactionsFinished {
  NSMutableArray<SKPaymentTransaction *> *unhandledTransactions = [[NSMutableArray alloc] init];
  dispatch_sync(self.paymentDataAccessQueue, ^{
    for (SKPaymentTransaction *transaction in transactions) {
      BOOL didHandleTransaction =
          [self handleTransaction:transaction transactionFinished:transactionsFinished];
      if (!transactionsFinished && !didHandleTransaction) {
        [unhandledTransactions addObject:transaction];
      }
    }
  });

  if ([unhandledTransactions count]) {
    [self.unhandledTransactionsSubject sendNext:[unhandledTransactions copy]];
  }
}

- (BOOL)handleTransaction:(SKPaymentTransaction *)transaction
      transactionFinished:(BOOL)transactionFinished {
  // If there's no associated payment try to find a matching one and pair it.
  if (!transaction.bzr_associatedPayment && [self pendingPaymentForTransaction:transaction] &&
      [self shouldPairPendingPaymentForTransaction:transaction
                               transactionFinished:transactionFinished]) {
    [self pairPendingPaymentWithTransaction:transaction];
  }

  // Handle transaction only if it has an associated payment.
  if (transaction.bzr_associatedPayment) {
    [self receivedTransaction:transaction transactionFinished:transactionFinished];
    return YES;
  }

  return NO;
}

- (void)receivedTransaction:(SKPaymentTransaction __unused *)transaction
        transactionFinished:(BOOL __unused)transactionFinished {
  /// This method is called when a transaction with a matching payment is received, and is observed
  /// using \c rac_signalForSelector. Therefore this method's implementation is empty.
}

- (BOOL)shouldPairPendingPaymentForTransaction:(SKPaymentTransaction *)transaction
                           transactionFinished:(BOOL)transactionFinished {
  return (transaction.transactionState == SKPaymentTransactionStatePurchasing ||
          transaction.transactionState == SKPaymentTransactionStateFailed) && !transactionFinished;
}

- (void)pairPendingPaymentWithTransaction:(SKPaymentTransaction *)transaction {
  SKPayment *payment = [self pendingPaymentForTransaction:transaction];
  [self.pendingPayments removeObjectAtIndex:[self.pendingPayments indexOfObject:payment]];
  transaction.bzr_associatedPayment = payment;
}

- (nullable SKPayment *)pendingPaymentForTransaction:(SKPaymentTransaction *)transaction {
  return [[self.pendingPayments lt_filter:^BOOL(SKPayment *payment) {
    return [transaction.payment isEqual:payment];
  }] firstObject];
}

#pragma mark -
#pragma mark Promoted IAP
#pragma mark -

- (BOOL)shouldProceedWithPromotedIAP:(SKProduct __unused *)product payment:(SKPayment *)payment {
  return [self.purchaseHelper shouldProceedWithPurchase:payment];
}

@end

NS_ASSUME_NONNULL_END
