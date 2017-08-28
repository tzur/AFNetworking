// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Hagai Weinfeld.

#import "BZRPurchaseManager.h"

#import <LTKit/NSArray+Functional.h>

#import "BZRPaymentsPaymentQueue.h"
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

/// Payments for which no transaction updates have arrived.
@property (readonly, nonatomic) NSMutableArray<SKPayment *> *pendingPayments;

/// Queue used for accessing \c pendingPayments.
@property (readonly, nonatomic) dispatch_queue_t paymentDataAccessQueue;

/// Sends transactions that are received from the delegate calls and are not associated with a
/// purchase made using the receiver.
@property (readonly, nonatomic) RACSubject *unhandledTransactionsSubject;

@end

@implementation BZRPurchaseManager

#pragma mark -
#pragma mark Initialization and Destruction
#pragma mark -

- (instancetype)initWithPaymentQueue:(id<BZRPaymentsPaymentQueue>)paymentQueue
                   applicationUserID:(nullable NSString *)applicationUserID {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    self.paymentQueue.paymentsDelegate = self;
    _applicationUserID = [applicationUserID copy];
    _pendingPayments = [[NSMutableArray alloc] init];
    _paymentDataAccessQueue =
        dispatch_queue_create("com.lightricks.bazaar.purchaseManager.dataAccessQueue",
                              DISPATCH_QUEUE_SERIAL);
    _unhandledTransactionsSubject = [RACSubject subject];
  }
  return self;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (RACSignal *)unhandledTransactionsSignal {
  return [self.unhandledTransactionsSubject takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark Purchasing
#pragma mark -

- (RACSignal *)purchaseProduct:(SKProduct *)product quantity:(NSUInteger)quantity {
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

- (RACSignal *)transactionUpdatesForPayment:(SKPayment *)payment {
  return [[[[[self rac_signalForSelector:@selector(receivedTransaction:transactionFinished:)]
      filter:^BOOL(RACTuple *tuple) {
        // Filter out updates for transactions that are not associated with the specified payment.
        return ((SKPaymentTransaction *)tuple.first).bzr_associatedPayment == payment;
      }]
      filter:^BOOL(RACTuple *tuple) {
        /// Filter out the update that inform about finishing the transaction in case the
        /// transaction failed. This filtering is required to avoid sending completion in case an
        /// error was previously sent.
        RACTupleUnpack(SKPaymentTransaction *transaction, NSNumber *transactionFinished) = tuple;
        return !([transactionFinished boolValue] &&
                 transaction.transactionState == SKPaymentTransactionStateFailed);
      }]
      map:^RACEvent *(RACTuple *tuple) {
        RACTupleUnpack(SKPaymentTransaction *transaction, NSNumber *transactionFinished) = tuple;
        if ([transactionFinished boolValue]) {
          return [RACEvent completedEvent];
        } else if (transaction.transactionState == SKPaymentTransactionStateFailed) {
          return [RACEvent eventWithError:
                  [NSError bzr_errorWithCode:BZRErrorCodePurchaseFailed transaction:transaction]];
        }
        return [RACEvent eventWithValue:transaction];
      }]
      dematerialize];
}

#pragma mark -
#pragma mark BZRPaymentQueuePaymentsDelegate
#pragma mark -

- (void)paymentQueue:(SKPaymentQueue __unused *)paymentQueue
    paymentTransactionsUpdated:(NSArray<SKPaymentTransaction *> *)transactions {
  [self handleTransactions:transactions transactionsFinished:NO];
}

- (void)paymentQueue:(SKPaymentQueue __unused *)paymentQueue
    paymentTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions {
  [self handleTransactions:transactions transactionsFinished:YES];
}

#pragma mark -
#pragma mark Handling Transaction Updates
#pragma mark -

- (void)handleTransactions:(NSArray<SKPaymentTransaction *> *)transactions
      transactionsFinished:(BOOL)transactionsFinished {
  dispatch_sync(self.paymentDataAccessQueue, ^{
    for (SKPaymentTransaction *transaction in transactions) {
      [self handleTransaction:transaction transactionFinished:transactionsFinished];
    }
  });
}

- (void)handleTransaction:(SKPaymentTransaction *)transaction
      transactionFinished:(BOOL)transactionFinished {
  if ([self doesTransactionHavePayment:transaction transactionFinished:transactionFinished]) {
    [self receivedTransaction:transaction transactionFinished:transactionFinished];
  } else if(!transactionFinished) {
    [self.unhandledTransactionsSubject sendNext:transaction];
  }
}

- (void)receivedTransaction:(SKPaymentTransaction __unused *)transaction
        transactionFinished:(BOOL __unused)transactionFinished {
  /// This method is called when a transaction with a matching payment is received, and is observed
  /// using \c rac_signalForSelector. Therefore this method's implementation is empty.
}

- (BOOL)doesTransactionHavePayment:(SKPaymentTransaction *)transaction
               transactionFinished:(BOOL)transactionFinished {
  if (transaction.bzr_associatedPayment) {
    return YES;
  }
  return [self shouldPairPendingPaymentForTransaction:transaction
                                  transactionFinished:transactionFinished] &&
      [self pairPendingPaymentWithTransaction:transaction];
}

- (BOOL)shouldPairPendingPaymentForTransaction:(SKPaymentTransaction *)transaction
                           transactionFinished:(BOOL)transactionFinished {
  return (transaction.transactionState == SKPaymentTransactionStatePurchasing ||
          transaction.transactionState == SKPaymentTransactionStateFailed) && !transactionFinished;
}

- (nullable SKPayment *)pairPendingPaymentWithTransaction:(SKPaymentTransaction *)transaction {
  SKPayment *payment = [self pendingPaymentForTransaction:transaction];
  if (payment) {
    [self pairPendingPayment:payment withTransaction:transaction];
  }
  return payment;
}

- (nullable SKPayment *)pendingPaymentForTransaction:(SKPaymentTransaction *)transaction {
  return [[self.pendingPayments lt_filter:^BOOL(SKPayment *payment) {
    return [transaction.payment isEqual:payment];
  }] firstObject];
}

- (void)pairPendingPayment:(SKPayment *)payment
           withTransaction:(SKPaymentTransaction *)transaction {
  [self.pendingPayments removeObjectAtIndex:[self.pendingPayments indexOfObject:payment]];
  transaction.bzr_associatedPayment = payment;
}

@end

NS_ASSUME_NONNULL_END
