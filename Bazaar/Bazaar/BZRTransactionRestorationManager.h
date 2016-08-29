// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

@protocol BZRRestorationPaymentQueue;

NS_ASSUME_NONNULL_BEGIN

/// Manager used to restore completed transactions.
@interface BZRTransactionRestorationManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c paymentQueue, used to restore transactions with. Setting \c paymentQueue's
/// \c restorationDelegate after the initialization of the receiver is considered undefined
/// behavior.
- (instancetype)initWithPaymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
     NS_DESIGNATED_INITIALIZER;

/// Restores all previously completed transactions made by the current user.
///
/// Returns a signal that initiates a restoration request upon subscription and sends the restored
/// transaction objects as they arrive, one by one. The values sent are \c SKPaymentTransaction
/// instances in the state of \c SKPaymentTransactionStateRestored. The signal completes when the
/// all previous transactions were restored and errs if restoration fails for any reason.
///
/// @returns <tt>RACSignal<SKPaymentTransaction></tt>
- (RACSignal *)restoreCompletedTransactions;

/// Restores all previously completed transactions made by the user specified by
/// \c applicationUserID.
///
/// Returns a signal that initiates a restoration request upon subscription and sends the restored
/// transaction objects as they arrive, one by one. The values sent are \c SKPaymentTransaction
/// instances in the state of \c SKPaymentTransactionStateRestored. The signal completes when the
/// all previous transactions were restored and errs if restoration fails for any reason.
///
/// @returns <tt>RACSignal<SKPaymentTransaction></tt>
- (RACSignal *)restoreCompletedTransactionsWithApplicationUserID:(NSString *)applicationUserID;

@end

NS_ASSUME_NONNULL_END
