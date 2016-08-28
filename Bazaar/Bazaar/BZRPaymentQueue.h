// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class BZRPaymentQueue;

/// Protocol for delegates that want to receive updates regarding payment transactions.
///
/// @note Payment transactions are added to the payment queue in response to payment requests made
/// by calling \c -[BZRPaymentQueue addPayment:].
@protocol BZRPaymentQueuePaymentsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that the state of the payment transactions in
/// \c transactions was updated.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue
    paymentTransactionsUpdated:(NSArray<SKPaymentTransaction *> *)transactions;

@optional

/// Invoked when \c paymentQueue informs its delegates that \c transactions were finished and
/// removed from the queue. \c transactions will contain only payment transactions and no
/// restoration transactions.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue
    paymentTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions;

@end

/// Protocol for delegates that want to receive updates regarding restored transactions.
///
/// @note Restored transactions are added to the payment queue in response to restoration requests
/// made by calling \c -[BZRPaymentQueue restoreCompletedTransactions] or
/// \c -[BZRPaymentQueue restoreCompletedTransactionsWithApplicationUsername:].
@protocol BZRPaymentQueueRestorationDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that \c transactions were restored.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue
transactionsRestored:(NSArray<SKPaymentTransaction *> *)transactions;

/// Invoked when \c paymentQueue informs its delegates that it completed restoring transactions.
- (void)paymentQueueRestorationCompleted:(BZRPaymentQueue *)paymentQueue;

/// Invoked when \c paymentQueue informs its delegates that it failed restoring transactions. Error
/// information is provided in \c error.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue restorationFailedWithError:(NSError *)error;

@optional

/// Invoked when \c paymentQueue informs its delegates that restored transactions in \c transactions
/// were marked as finished and removed from the queue. \c transactions will contain only restored
/// transactions and no payment transactions.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue
    restoredTransactionsRemoved:(NSArray<SKPaymentTransaction *> *)transactions;

@end

/// Protocol for delegates that want to to receive updates regarding product content downloads.
@protocol BZRPaymentQueueDownloadsDelegate <NSObject>

/// Invoked when \c paymentQueue informs its delegates that the state of downloads in \c downloads
/// was updated.
- (void)paymentQueue:(BZRPaymentQueue *)paymentQueue
    updatedDownloads:(NSArray<SKDownload *> *)downloads;

@end

/// \c BZRPaymentQueue provides an interface for making payments, restoring completed transactions,
/// and managing downloads. Its methods correspond to the methods of \c SKPaymentQueue.
@protocol BZRPaymentQueue

/// Adds a payment request. Will initiate sending updates of transaction associated with \c payment
/// to \c paymentsDelegate.
- (void)addPayment:(SKPayment *)payment;

/// Restores completed transactions. Will initiate sending updates of restored transactions to
/// \c restorationDelegate.
- (void)restoreCompletedTransactions;

/// Restores completed transactions with username specified by \c username, or with the default
/// username if \c username is \c nil. Will initiate sending updates of restored transactions to
/// \c restorationDelegate.
- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username;

/// Finishes a transaction. The transaction should no longer be used afterwards.
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

/// Starts downloading the content from each download in \c downloads. Will initiate sending updates
/// of downloads to \c downloadsDelegate.
- (void)startDownloads:(NSArray<SKDownload *> *)downloads;

/// Cancels downloading the content from each download in \c downloads.
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;

/// Array of unfinished transactions created by the underlying \c SKPaymentQueue.
@property (readonly, nonatomic) NSArray<SKPaymentTransaction *> *transactions;

@end

/// \c BZRPaymentQueue acts as a proxy between \c SKPaymentQueue and 3 delegates of different
/// category. It splits the callbacks into 3 categories and forwards the methods of each category to
/// a designated delegate. The categories and their corresponding delegates are:
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
/// In order for the delegates to receive updates this class is registered as an observer to an
/// \c SKPaymentQueue using \c -[SKPaymentQueue addTransactionObserver:]
/// When finished observing this class removes itself by using
/// \c -[SKPaymentQueue removeTransactionObserver:]. Since the internal payment queue may defer
/// purchases to a later time (due to parental control policy for example), updates may be delivered
/// out of order and at any time during the application life time. Hence it is recommended to
/// instantiate this class as soon as possible in the application life time.
///
/// @note It is recommended by Apple to have only one observer registered to a payment queue. Hence,
/// only one \c BZRPaymentQueue should be instantiated.
///
/// @see SKPaymentQueue, SKPaymentTransactionObserver, SKPaymentTransaction, SKDownload.
@interface BZRPaymentQueue : NSObject<BZRPaymentQueue>

/// Initializes with \c underlyingPaymentQueue, set to \c -[SKPaymentQueue defaultQueue].
///
/// @see initWithPaymentQueue:
- (instancetype)init;

/// Initializes with \c underlyingPaymentQueue, used to be notified of transactions and downloads
/// updates.
- (instancetype)initWithUnderlyingPaymentQueue:(SKPaymentQueue *)underlyingPaymentQueue
    NS_DESIGNATED_INITIALIZER;

/// Delegate that will be receiving updates regarding payment transactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueuePaymentsDelegate> paymentsDelegate;

/// Delegate that will be receiving updates regarding restored transactions.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueRestorationDelegate> restorationDelegate;

/// Delegate that will be receiving update regarding content downloads.
@property (weak, nonatomic, nullable) id<BZRPaymentQueueDownloadsDelegate> downloadsDelegate;

@end

NS_ASSUME_NONNULL_END
