// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@protocol BZRPaymentQueueRestorationDelegate;

/// \c BZRPaymentQueue provides an interface for restoring completed transactions and sending
/// updates regarding restored transactions.
@protocol BZRRestorationPaymentQueue <NSObject>

/// Restores completed transactions. Will initiate sending updates of restored transactions to
/// \c restorationDelegate.
- (void)restoreCompletedTransactions;

/// Restores completed transactions with username specified by \c username, or with the default
/// username if \c username is \c nil. Will initiate sending updates of restored transactions to
/// \c restorationDelegate.
- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username;

/// Delegate that will be receiving updates regarding restored transactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueRestorationDelegate> restorationDelegate;

@end

/// Protocol for delegates that want to receive updates regarding restored transactions.
///
/// @note Restored transactions are added to the payment queue in response to restoration requests
/// made by calling \c -[BZRPaymentQueue restoreCompletedTransactions] or
/// \c -[BZRPaymentQueue restoreCompletedTransactionsWithApplicationUsername:].
@protocol BZRPaymentQueueRestorationDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that \c transactions were restored.
- (void)paymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
    transactionsRestored:(NSArray<SKPaymentTransaction *> *)transactions;

/// Invoked when \c paymentQueue informs its delegates that it completed restoring transactions.
- (void)paymentQueueRestorationCompleted:(id<BZRRestorationPaymentQueue>)paymentQueue;

/// Invoked when \c paymentQueue informs its delegates that it failed restoring transactions. Error
/// information is provided in \c error.
- (void)paymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
    restorationFailedWithError:(NSError *)error;

@optional

/// Invoked when \c paymentQueue informs its delegates that restored transactions in \c transactions
/// were marked as finished and removed from the queue. \c transactions will contain only restored
/// transactions and no payment transactions.
- (void)paymentQueue:(id<BZRRestorationPaymentQueue>)paymentQueue
    restoredTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions;

@end

NS_ASSUME_NONNULL_END
