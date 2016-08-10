// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for delegates that want to receive updates regarding payment transactions.
///
/// @note Payment transactions are added to the payment queue in response to payment requests made
/// by calling \c - [SKPaymentQueue addPayment:].
@protocol BZRPaymentQueuePaymentsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its observers that the state of the payment transactions in
/// \c transactions was updated.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue
    paymentTransactionsUpdated:(NSArray<SKPaymentTransaction *> *)transactions;

@optional

/// Invoked when \c paymentQueue informs its observers that \c transactions were finished and
/// removed from the queue. \c transactions will contain only payment transactions and no
/// restoration transactions.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue
    paymentTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions;

@end

/// Protocol for delegates that want to receive updates regarding restored transactions.
///
/// @note Restored transactions are added to the payment queue in response to restoration requests
/// made by calling \c - [SKPaymentQueue restoreCompletedTransactions].
@protocol BZRPaymentQueueRestorationDelegate <NSObject>

/// Invoked when \c paymentQueue informs its observers that \c transactions were restored.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue
transactionsRestored:(NSArray<SKPaymentTransaction *> *)transactions;

/// Invoked when \c paymentQueue informs its observers that it completed restoring transactions.
- (void)paymentQueueRestorationCompleted:(SKPaymentQueue *)paymentQueue;

/// Invoked when \c paymentQueue informs its observers that it failed restoring transactions. Error
/// information is provided in \c error.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue restorationFailedWithError:(NSError *)error;

@optional

/// Invoked when \c paymentQueue informs its observers that restored transactions in \c transactions
/// were marked as finished and removed from the queue. \c transactions will contain only restored
/// transactions and no payment transactions.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue
    restoredTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions;

@end

/// Protocol for delegates that want to to receive updates regarding product content downloads.
@protocol BZRPaymentQueueDownloadsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its observers that the state of downloads in \c downloads
/// was updated.
- (void)paymentQueue:(SKPaymentQueue *)paymentQueue
    updatedDownloads:(NSArray<SKDownload *> *)downloads;

@end

/// \c BZRPaymentQueueObserver acts as an observer for \c SKPaymentQueue that splits the callbacks
/// of \c SKPaymentTransactionObserver into 3 categories and forwards the methods of each category
/// to a designated delegate. The categories and their corresponding delegates are:
///
/// - Payment transaction updates are forwarded to a \c BZRPaymentQueuePaymentsDelegate.
///
/// - Transaction restoration updates are forwarded to a \c BZRPaymentQueueRestorationDelegate.
///
/// - Content downloading updates are forwarded to \c BZRPaymentQueueDownloadsDelegate.
///
/// This allows better separation of concerns - each delegate receives updates only on transactions
/// or downloads that are relevant to it.
///
/// In order for the delegates of a \c BZRPaymentQueueObserver to receive updates the
/// \c BZRPaymentQueueObserver must be registered as an observer to an \c SKPaymentQueue using
/// \c - [SKPaymentQueue addTransactionObserver:]. When finished observing the payment queue remove
/// the observer using \c - [SKPaymentQueue removeTransactionObserver:]. Since payment queue may
/// defer purchases to a later time (due to parental control policy for example) updates may be
/// delivered out of order and at any time during the application life time. Hence it is recommended
/// to register an observer to the payment queue as soon as possible in the application life time.
///
/// @note It is recommended by Apple to have only one observer registered to a payment queue.
///
/// @see SKPaymentQeue, SKPaymentTransactionObserver, SKPaymentTransaction, SKDownload.
@interface BZRPaymentQueueObserver : NSObject <SKPaymentTransactionObserver>

/// Delegate that will be receiving updates regarding payment transactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueuePaymentsDelegate> paymentsDelegate;

/// Delegate that will be receiving updates regarding restored trasnactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueRestorationDelegate> restorationDelegate;

/// Delegate that will be receiving update regarding content downloads.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueDownloadsDelegate> downloadsDelegate;

@end

NS_ASSUME_NONNULL_END
