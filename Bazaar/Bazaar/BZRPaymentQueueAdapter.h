// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRDownloadsPaymentQueue.h"
#import "BZREventEmitter.h"
#import "BZRPaymentsPaymentQueue.h"
#import "BZRRestorationPaymentQueue.h"
#import "BZRStoreKitTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BZRPaymentQueue;

/// \c BZRPaymentQueue acts as a proxy between \c id<BZRInternalPaymentQueue> and 3 delegates of
/// different category. It splits the callbacks into 3 categories and forwards the methods of each
/// category to a designated delegate. The categories and their corresponding delegates are:
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
/// In order for the delegates to receive updates, this class registers itself as an observer to the
/// given \c id<BZRInternalPaymentQueue> using \c addTransactionObserver:.
/// When deallocating this class removes itself by using \c removeTransactionObserver:. Since the
/// internal payment queue may defer purchases to a later time (due to parental control policy for
/// example), updates may be delivered out of order and at any time during the application life
/// time. Hence it is recommended to instantiate this class as soon as possible in the application
/// life time.
///
/// @note It is recommended by Apple to have only one observer registered to a payment queue. Hence,
/// only one \c BZRPaymentQueue should be instantiated.
///
/// @see SKPaymentQueue, SKPaymentTransactionObserver, SKPaymentTransaction, SKDownload.
@interface BZRPaymentQueueAdapter : NSObject <BZRDownloadsPaymentQueue, BZREventEmitter,
                                              BZRPaymentsPaymentQueue, BZRRestorationPaymentQueue>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c underlyingPaymentQueue, used to be notified of transactions and downloads
/// updates.
- (instancetype)initWithPaymentQueue:(id<BZRPaymentQueue>)underlyingPaymentQueue
    NS_DESIGNATED_INITIALIZER;

/// Finishes a transaction. The transaction should no longer be used afterwards.
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

/// Sends transactions of payments and restorations that were initiated on a previous run of the
/// application and weren't finished. The \c SKPaymentTransaction can be either in a failed,
/// purchased or restored state. The signal completes when the receiver is deallocated. The signal
/// doesn't err.
@property (readonly, nonatomic) RACSignal<BZRPaymentTransactionList *> *
    unfinishedTransactionsSignal;

@end

NS_ASSUME_NONNULL_END
