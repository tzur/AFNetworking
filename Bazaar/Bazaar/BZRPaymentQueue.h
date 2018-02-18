// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol that declares the same methods as \c SKPaymentQueue so that \c SKPaymentQueue can be
/// replaced with a fake object easily.
///
/// @see https://developer.apple.com/documentation/storekit/skpaymentqueue?language=objc for more
/// details on \c SKPaymentQueue.
@protocol BZRPaymentQueue <NSObject>

/// Adds \c payment to the queue and initiates the purchasing process.
- (void)addPayment:(SKPayment *)payment;

/// Initiates a transaction restoration process. The observers will receive a new transaction for
/// each previously completed transaction that can be restored. The \c originalTransaction property
/// of each restored transaction will point to the original purchase transaction
- (void)restoreCompletedTransactions;

/// Same as \c restoreCompletedTransactions, but accepts an application's username.
- (void)restoreCompletedTransactionsWithApplicationUsername:(nullable NSString *)username;

/// Finishes the given \c transaction. This will remove \c transaction from the queue, and it will
/// no longer possible to use that transaction with any StoreKit methods.
///
/// @note Calling finishTransaction: on a transaction that is in the
/// \c SKPaymentTransactionStatePurchasing state throws an exception.
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

/// Starts the downloads specified by \c downloads.
- (void)startDownloads:(NSArray<SKDownload *> *)downloads;

/// Pause the downloads specified by \c downloads.
- (void)pauseDownloads:(NSArray<SKDownload *> *)downloads;

/// Resumes the downloads specified by \c downloads.
- (void)resumeDownloads:(NSArray<SKDownload *> *)downloads;

/// Cancels the downloads specified by \c downloads.
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;

/// Adds \c observer as an observer to the receiver. The observer will be notified when transactions
/// are updated and removed, the status of transaction restoration, the status of downloads, etc.
/// The \c observer is held weakly.
///
/// @see SKPaymentTransactionObserver.
- (void)addTransactionObserver:(id<SKPaymentTransactionObserver>)observer;

/// Removes \c observer as an observer from the receiver.
- (void)removeTransactionObserver:(id<SKPaymentTransactionObserver>)observer;

/// Holds an array of unfinished \c SKPaymentTransactions.
/// @note Only valid while the queue has observers.
@property (readonly, nonatomic) NSArray<SKPaymentTransaction *> *transactions;

@end

NS_ASSUME_NONNULL_END
