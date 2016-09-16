// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRDownloadsPaymentQueue.h"
#import "BZRPaymentsPaymentQueue.h"
#import "BZRRestorationPaymentQueue.h"

NS_ASSUME_NONNULL_BEGIN

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
/// In order for the delegates to receive updates, this class is registered as an observer to an
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
@interface BZRPaymentQueue : NSObject <BZRDownloadsPaymentQueue, BZRPaymentsPaymentQueue,
                                       BZRRestorationPaymentQueue>

/// Initializes with \c underlyingPaymentQueue set to \c -[SKPaymentQueue defaultQueue], and with
/// \c unfinishedTransactionsSubject set to \c nil.
///
/// @see initWithPaymentQueue:unfinishedTransactionsSubject:
- (instancetype)init;

/// Initializes with \c underlyingPaymentQueue set to \c -[SKPaymentQueue defaultQueue], and with
/// \c unfinishedTransactionsSubject set to \c unfinishedTransactionsSubject.
///
/// @see initWithPaymentQueue:unfinishedTransactionsSubject:
- (instancetype)initWithUnfinishedTransactionsSubject:(nullable RACSubject *)
    unfinishedTransactionsSubject;

/// Initializes with \c underlyingPaymentQueue, used to be notified of transactions and downloads
/// updates, and with \c unfinishedTransactionsSubject, used to send an array of unfinished
/// transactions.
///
/// \c SKPaymentQueue sends all transactions that weren't finished from the last run of the
/// application when an observer is added to it. \c BZRPaymentQueue adds an observer to it at
/// initialization, but \c BZRPaymentQueue's underlying delegates are \c nil. As a result, these
/// transactions will never be handled. The solution is to pass a subject that should already be
/// subscribed to, which will send the transactions as they arrive. The transactions will be sent to
/// the delegates instead of the subject as soon as \c addPayment or
/// \c restoreCompletedTransactionsWithApplicationUsername were called, because this is when the
/// delegates start to expect transactions to arrive.
- (instancetype)initWithUnderlyingPaymentQueue:(SKPaymentQueue *)underlyingPaymentQueue
                 unfinishedTransactionsSubject:(nullable RACSubject *)unfinishedTransactionsSubject
    NS_DESIGNATED_INITIALIZER;

/// Finishes a transaction. The transaction should no longer be used afterwards.
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
