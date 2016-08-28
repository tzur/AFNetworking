// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRTransactionRestorationManager.h"

#import "BZRRestorationPaymentQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRTransactionRestorationManager () <BZRPaymentQueueRestorationDelegate>

/// Used to restore completed transactions with.
@property (readonly, nonatomic) id<BZRRestorationPaymentQueue> paymentQueue;

@end

@implementation BZRTransactionRestorationManager

- (instancetype)initWithPaymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue {
  if (self = [super init]) {
    _paymentQueue = paymentQueue;
    paymentQueue.restorationDelegate = self;
  }
  return self;
}

- (RACSignal *)restoreCompletedTransactions {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    RACSignal *transactionsSignal = [[self restoredTransactionsSignal] replay];
    [self.paymentQueue restoreCompletedTransactions];
    return transactionsSignal;
  }];
}

- (RACSignal *)restoreCompletedTransactionsWithApplicationUserID:(NSString *)applicationUserID {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    RACSignal *transactionsSignal = [[self restoredTransactionsSignal] replay];
    [self.paymentQueue restoreCompletedTransactionsWithApplicationUsername:applicationUserID];
    return transactionsSignal;
  }];
}

- (RACSignal *)restoredTransactionsSignal {
  return [[[RACSignal
      merge:@[[self restoredTransactionsUpdatesSignal], [self failureSignal]]]
      takeUntil:[self completionSignal]]
      flattenMap:^RACStream *(RACTuple *tuple) {
        return ((NSArray *)tuple.second).rac_sequence.signal;
      }];
}

- (RACSignal *)restoredTransactionsUpdatesSignal {
  return [self rac_signalForSelector:@selector(paymentQueue:transactionsRestored:)];
}

- (RACSignal *)completionSignal {
  return [[self rac_signalForSelector:@selector(paymentQueueRestorationCompleted:)] take:1];
}

- (RACSignal *)failureSignal {
  return [[[self rac_signalForSelector:@selector(paymentQueue:restorationFailedWithError:)]
      take:1]
      flattenMap:^RACStream *(RACTuple *parameters) {
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
