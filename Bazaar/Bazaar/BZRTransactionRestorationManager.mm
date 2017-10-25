// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRTransactionRestorationManager.h"

#import "BZRRestorationPaymentQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRTransactionRestorationManager () <BZRPaymentQueueRestorationDelegate>

/// Used to restore completed transactions with.
@property (readonly, nonatomic) id<BZRRestorationPaymentQueue> paymentQueue;

/// Application user identifier to use when restoring transactions.
@property (readonly, nonatomic, nullable) NSString *applicationUserID;

@end

@implementation BZRTransactionRestorationManager

- (instancetype)initWithPaymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
                   applicationUserID:(nullable NSString *)applicationUserID {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    _applicationUserID = applicationUserID;
    paymentQueue.restorationDelegate = self;
  }
  return self;
}

- (RACSignal<SKPaymentTransaction *> *)restoreCompletedTransactions {
  @weakify(self);
  return [RACSignal defer:^{
    @strongify(self);
    RACSignal<SKPaymentTransaction *> *transactionsSignal =
        [[self restoredTransactionsSignal] replay];
    [self.paymentQueue restoreCompletedTransactionsWithApplicationUserID:self.applicationUserID];
    return transactionsSignal;
  }];
}

- (RACSignal<SKPaymentTransaction *> *)restoredTransactionsSignal {
  return [[[RACSignal
      merge:@[[self restoredTransactionsUpdatesSignal], [self failureSignal]]]
      takeUntil:[self completionSignal]]
      flattenMap:^(RACTuple *tuple) {
        return ((NSArray *)tuple.second).rac_sequence.signal;
      }];
}

- (RACSignal<RACTuple *> *)restoredTransactionsUpdatesSignal {
  return [self rac_signalForSelector:@selector(paymentQueue:transactionsRestored:)];
}

- (RACSignal *)completionSignal {
  return [[self rac_signalForSelector:@selector(paymentQueueRestorationCompleted:)] take:1];
}

- (RACSignal *)failureSignal {
  return [[[self rac_signalForSelector:@selector(paymentQueue:restorationFailedWithError:)]
      take:1]
      flattenMap:^(RACTuple *parameters) {
        return [RACSignal error:parameters.second];
      }];
}

#pragma mark -
#pragma mark BZRPaymentQueueRestorationDelegate
#pragma mark -

- (void)paymentQueue:(id<BZRRestorationPaymentQueue> __unused)paymentQueue
transactionsRestored:(NSArray<SKPaymentTransaction *> __unused *)transactions {
  // Required by protocol.
}

- (void)paymentQueueRestorationCompleted:(id<BZRRestorationPaymentQueue> __unused)paymentQueue {
  // Required by protocol.
}

- (void)paymentQueue:(id<BZRRestorationPaymentQueue> __unused)paymentQueue
    restorationFailedWithError:(NSError __unused *)error {
  // Required by protocol.
}

@end

NS_ASSUME_NONNULL_END
