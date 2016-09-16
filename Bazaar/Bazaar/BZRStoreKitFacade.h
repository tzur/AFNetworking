// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class  BZRPaymentQueue, BZRProductDownloadManager, BZRPurchaseManager,
    BZRTransactionRestorationManager;

@protocol BZRStoreKitRequestsFactory;

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
@interface BZRStoreKitFacade : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c unfinishedTransactionSubject, used to send an array of unfinished
/// transactions. \c applicationUserID is an optional unique identifier for the user’s account.
/// \c paymentQueue will be initialized using
/// \c -[BZRPaymentQueue initWithUnfinishedTransactionsSubject:]. \c purchaseManager will be
/// initialized using \c -[BZRPurchaseManager initWithPaymentQueue:applicationUserID:].
/// \c restorationManager will be initialized using
/// \c [BZRTransactionRestorationManager initWithPaymentQueue:applicationUserID:].
/// \c downloadManager will be using \c [BZRProductDownloadManager initWithPaymentQueue:].
/// \c storeKitRequestsFactory will be initialized using \c [BZRStoreKitRequestsFactory init].
///
/// @note Using this method, one can handle transactions that were not finished during the previous
/// execution of the application. One should supply a subject that he is already subscribed to, and
/// an array of unfinished transactions will be sent using that subject.
///
/// @note The \c applicationUserID is a user ID provided by the application that uniquely identifies
/// the user (i.e. it must be different for different users and identical for the same user across
/// devices). If it is not \c nil, it will be used when making purchases to assist with fraud
/// detection. For more information about the application user identifier follow this link:
/// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StoreKitGuide/Chapters/RequestPayment.html#//apple_ref/doc/uid/TP40008267-CH4-SW6
///
/// @see \c -[self initWithPaymentQueue:purchaseManager:restorationManager:downloadManager:
///           storeKitRequestsFactory:]
- (instancetype)initWithUnfinishedTransactionsSubject:(RACSubject *)unfinishedTransactionsSubject
                                    applicationUserID:(nullable NSString *)applicationUserID;

/// Initializes with \c paymentQueue, used to observe an underlying \c SKPaymentQueue and pass calls
/// from the \c SKPaymentQueue to \c paymentQueue's appropriate delegate. \c purchaseManager is used
/// to make products purchases with StoreKit. \c restorationManager is used to restore completed
/// transactions. \c downloadManager is used to download content of products.
/// \c storeKitRequestsFactory is used to create StoreKit's requests.
- (instancetype)initWithPaymentQueue:(BZRPaymentQueue *)paymentQueue
                     purchaseManager:(BZRPurchaseManager *)purchaseManager
                  restorationManager:(BZRTransactionRestorationManager *)restorationManager
                     downloadManager:(BZRProductDownloadManager *)downloadManager
             storeKitRequestsFactory:(id<BZRStoreKitRequestsFactory>)storeKitRequestsFactory
    NS_DESIGNATED_INITIALIZER;

/// Fetches metadata for products with the specified \c productIdentifiers.
///
/// Returns a signal that initiates an \c SKProductsRequest upon subscription. The signal sends an
/// \c SKProductsResponse if the request is successful and then completes. The signal errs if the
/// request fails for any reason.
///
/// @note \c SKProductResponse contains an array of \c SKProduct objects each containing metadata on
/// a single product. The \c SKProduct instances can later be used for purchasing the products.
///
/// @note If \c productIdentifiers contains some invalid product identifiers they will be listed 
/// in the response object under \c invalidProductIdentifiers.
///
/// @return <tt>RACSignal<SKProductsResponse></tt>
- (RACSignal *)fetchMetadataForProductsWithIdentifiers:(NSSet<NSString *> *)productIdentifiers;

/// Purchases a single \c product from the store.
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
/// @return <tt>RACSignal<SKPaymentTransaction></tt>
- (RACSignal *)purchaseProduct:(SKProduct *)product;

/// Purchases \c quantity units of a consumable \c product. \c quantity must be a positive number,
/// if \c 0 is passed an \c NSInvalidArgumentException is raised.
///
/// Returns a signal that initiates a payment request upon subscription. It sends an instance of
/// \c SKPaymentTransaction that was created for the payment request. That \c SKPaymentTransaction
/// is sent whenever its state is updated. The signal completes when \c finishTransaction is called
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
/// @return <tt>RACSignal<SKPaymentTransaction></tt>
- (RACSignal *)purchaseConsumableProduct:(SKProduct *)product quantity:(NSUInteger)quantity;

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
///
/// @return <tt>NSArray<RACSignal<SKDownload>></tt>
- (NSArray<RACSignal *> *)downloadContentForTransaction:(SKPaymentTransaction *)transaction;

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
///
/// @return <tt>RACSignal<SKPaymentTransaction></tt>
- (RACSignal *)restoreCompletedTransactions;

/// Refreshes the AppStore receipt of the application.
///
/// Returns a signal that initiates receipt refresh request upon subscription. The signal completes
/// when receipt refresh completed successfully end errs if refreshing failed.
///
/// @note Receipt refreshing request causes the StoreKit to show a login dialog, requesting the user
/// to enter his Apple ID and password in order to approve the refresh request.
///
/// @return <tt>RACSignal</tt>
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

/// Sends errors encompassing transactions that are received by \c purchaseManager and are not
/// associated with a purchase made using it. The signal completes when the receiver is deallocated.
/// The signal doesn't err.
///
/// @return <tt>RACSubject<NSError></tt>
@property (readonly, nonatomic) RACSignal *unhandledTransactionsErrorsSignal;

@end

NS_ASSUME_NONNULL_END
