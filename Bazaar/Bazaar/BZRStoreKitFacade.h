// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"
#import "BZRStoreKitTypedefs.h"

NS_ASSUME_NONNULL_BEGIN

@class BZREvent, BZRPaymentQueueAdapter, BZRProductDownloadManager, BZRPurchaseManager,
    BZRTransactionRestorationManager;

@protocol BZRPurchaseHelper, BZRStoreKitRequestsFactory;

/// \c BZRStoreKitFacade provides a unified reactive interface on top of Apple's StoreKit framework.
///
/// \c BZRStoreKitFacade is a thin wrapper around Apple's StoreKit, it works directly with StoreKit
/// objects - some of these objects are passed as parameters to the facade and few are being sent
/// on signals the facade returns. The facade provides methods for fetching products metadata,
/// purchasing products, downloading per-product resources, restoring previously purchased products
/// and refreshing the application receipt.
///
/// @see SKDownload, SKPayment, SKPaymentQueue, SKProduct, SKProductsRequest, SKProductResponse,
/// SKPaymentTransaction.
@interface BZRStoreKitFacade : NSObject <BZREventEmitter>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c applicationUserID is an optional unique identifier for the user’s account.
///\c paymentQueueAdapter will be initialized with \c [SKPaymentQueue defaultQueue].
/// \c purchaseManager will be initialized using
/// \c -[BZRPurchaseManager initWithPaymentQueue:applicationUserID:purchaseHelper:].
/// \c restorationManager will be initialized using
/// \c [BZRTransactionRestorationManager initWithPaymentQueue:applicationUserID:].
/// \c downloadManager will be using \c [BZRProductDownloadManager initWithPaymentQueue:].
/// \c storeKitRequestsFactory will be initialized using \c [BZRStoreKitRequestsFactory init].
///
/// @note The \c applicationUserID is a user ID provided by the application that uniquely identifies
/// the user (i.e. it must be different for different users and identical for the same user across
/// devices). If it is not \c nil, it will be used when making purchases to assist with fraud
/// detection. For more information about the application user identifier follow this link:
/// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW6
///
/// @see \c -[self initWithPaymentQueue:purchaseManager:restorationManager:downloadManager:
///           storeKitRequestsFactory:]
- (instancetype)initWithApplicationUserID:(nullable NSString *)applicationUserID
                           purchaseHelper:(id<BZRPurchaseHelper>)purchaseHelper;

/// Initializes with \c paymentQueueAdapter, used to observe an underlying \c SKPaymentQueue and
/// pass calls from the \c SKPaymentQueue to \c paymentQueue's appropriate delegate. \c
/// purchaseManager is used to make products purchases with StoreKit. \c restorationManager is used
/// to restore completed transactions. \c downloadManager is used to download content of products.
/// \c storeKitRequestsFactory is used to create StoreKit's requests.
- (instancetype)initWithPaymentQueueAdapter:(BZRPaymentQueueAdapter *)paymentQueueAdapter
                            purchaseManager:(BZRPurchaseManager *)purchaseManager
                         restorationManager:(BZRTransactionRestorationManager *)restorationManager
                            downloadManager:(BZRProductDownloadManager *)downloadManager
                    storeKitRequestsFactory:(id<BZRStoreKitRequestsFactory>)storeKitRequestsFactory
    NS_DESIGNATED_INITIALIZER;

/// Fetches metadata for products with the specified \c productIdentifiers.
///
/// Returns a signal that initiates an \c SKProductsRequest upon subscription. The signal sends an
/// \c SKProductsResponse if the request is successful and then completes. The signal errs if the
/// request fails for any reason. Values are not delivered on the main thread.
///
/// @note \c SKProductResponse contains an array of \c SKProduct objects each containing metadata on
/// a single product. The \c SKProduct instances can later be used for purchasing the products.
///
/// @note If \c productIdentifiers contains some invalid product identifiers they will be listed
/// in the response object under \c invalidProductIdentifiers.
- (RACSignal<SKProductsResponse *> *)
    fetchMetadataForProductsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers;

/// Purchases \c quantity units of \c product. \c quantity must be a positive number, if \c 0 is
/// passed an \c NSInvalidArgumentException is raised.
///
/// Returns a signal that initiates a payment request upon subscription. It sends an instance of
/// \c SKPaymentTransaction that was created for the payment request. That \c SKPaymentTransaction
/// is sent whenever its state is updated. The signal completes when \c finishTransaction was called
/// for the transaction and errs if the transaction reaches the \c SKPaymentTransactionStateFailed
/// state.
///
/// @note Some products, in order to function properly require additional resources that are
/// available from the AppStore. Once a payment transaction has reached the state
/// \c SKPaymentTransactionStatePurchased or \c SKPaymentTransactionStateRestored its \c downloads
/// property will hold an array of \c SKDownload objects that can be used to download these
/// complementary resources.
///
/// @note When a transaction object is no longer needed one must call \c finishTransaction: on the
/// store manager. This method should be invoked for completed, restored and failed transactions.
///
/// @note If the purchase was cancelled, the signal will err with an error code
/// \c BZRErrorCodeOperationCancelled.
- (RACSignal<SKPaymentTransaction *> *)purchaseProduct:(SKProduct *)product
                                              quantity:(NSUInteger)quantity;

/// Downloads additional content for a completed \c transaction.
///
/// The transaction object must be either in the \c SKPaymentTransactionStatePurchased or
/// \c SKPaymentTransactionStateRestored and it must not be finished, otherwise an
/// \c NSInvalidArgumentException is raised.
///
/// Returns an array of signals, each is associated with one of the \c SKDownload objects attached
/// to \c transaction. Each of the signals initiates a download request upon subscription and sends
/// the associated \c SKDownload object as value whenever its state updates. Each of The signals
/// completes when its associated \c SKDownload object reaches the \c SKDownloadStateFinished state
/// and errs with an appropriate error if its associated \c SKDownload object reaches the
/// \c SKDownloadStateFailed state.
- (NSArray<RACSignal<SKDownload *> *> *)
    downloadContentForTransaction:(SKPaymentTransaction *)transaction;

/// Restores all previously completed transactions made by the current user.
///
/// Returns a signal that initiates a restoration request upon subscription and sends the restored
/// transaction objects as they arrive, one by one. The values sent are \c SKPaymentTransaction
/// instances in the state of \c SKPaymentTransactionStateRestored. The signal completes when all
/// previous transactions were restored and errs if restoration fails for any reason.
///
/// @note When a transaction object is no longer needed one must call \c finishTransaction: on the
/// store manager. This method should be invoked for completed, restored and failed transactions.
///
/// @note Restore completed transactions causes the StoreKit to show a login dialog, requesting the
/// user to enter his Apple ID and password in order to approve the restoration.
- (RACSignal<SKPaymentTransaction *> *)restoreCompletedTransactions;

/// Refreshes the AppStore receipt of the application.
///
/// Returns a signal that initiates receipt refresh request upon subscription. The signal completes
/// when receipt refresh completed successfully end errs if refreshing failed.
///
/// @note Receipt refreshing request causes the StoreKit to show a login dialog, requesting the user
/// to enter his Apple ID and password in order to approve the refresh request.
- (RACSignal *)refreshReceipt;

/// Finishes a completed \c transaction and removes it from the transaction queue.
///
/// Calling this method on an incomplete transaction will raise \c NSInvalidArgumentException.
/// Completed transactions are transactions in one of the following states:
/// \c SKPaymentTransactionStatePurchased, \c SKPaymentTransactionStateFailed,
/// \c SKPaymentTransactionStateRestored.
///
/// Any completed transaction should be finished when it is no longer needed. Failing to finish
/// completed transactions may hold resources that are no longer needed and can hit performance.
/// Transactions are not removed automatically from the payment queue and hence will be sent again
/// on \c unfinishedTransactionsSubject given in the initializer the next time the application
/// starts.
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

/// Array of unfinished transactions.
@property (readonly, nonatomic) NSArray<SKPaymentTransaction *> *transactions;

/// Sends all transactions related errors as \c BZREvent encompassing an \c NSError. The events can
/// can be one of the following:
/// \c BZREventTypeUnhandledTransactionReceived - when a transaction without an associated payment
/// is received via \c purchaseManager.
/// \c BZREventTypePurchaseFailed - when an unfinished failed transaction is received.
/// The signal completes when the receiver is deallocated. The signal doesn't err.
@property (readonly, nonatomic) RACSignal<BZREvent *> *transactionsErrorEventsSignal;

/// Sends array of transactions that were completed successfully and do not match any pending
/// payment request. The \c SKPaymentTransaction can be either in the purchased or restored state.
/// The signal completes when the receiver is deallocated. The signal doesn't err.
///
/// @note The transactions sent here can be received in one of the following scenarios:
/// 1. Purchases that were initiated outside of the app (eg. subscription renewals or upgrades).
/// 2. Purchases that were initiated in previous run of the app and weren't finished yet (eg.
/// communication error at the final stages of a successful purchase / restoration or app were
/// killed before transaction was finished).
/// 3. SOON: Deferred purchases that were in pending state and were later approved and completed.
@property (readonly, nonatomic) RACSignal<BZRPaymentTransactionList *> *
    unhandledSuccessfulTransactionsSignal;

@end

NS_ASSUME_NONNULL_END
