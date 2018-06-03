// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRProduct, BZRReceiptValidationStatus, BZRRedeemConsumablesStatus, BZRUserCreditStatus,
    LTProgress<ResultType : id<NSObject>>, SKPaymentTransaction;

/// A unified interface for managing an products. The products manager provides methods for:
///
///   - Refreshing the receipt.
///
///   - Purchasing products.
///
///   - Fetching/deleting products' content.
///
///   - Getting the list of products that was last fetched.
@protocol BZRProductsManager <BZREventEmitter>

/// Makes a purchase of the product specified by \c productIdentifier. Events can be sent on an
/// arbitrary thread.
///
/// Returns a signal that makes a purchase of the product and completes. The signal doesn't download
/// the content of the product. To do so, \c fetchProductContent should be called. The signal errs
/// if there was an error in the purchase.
///
/// @note If the purchase was cancelled, the signal will err with an error code
/// \c BZRErrorCodeOperationCancelled.
///
/// @note If the purchase failed and the underlying error's code is
/// \c BZRErrorCodeTransactionNotFoundInReceipt, it is possible to retry finalizing the purchase by
/// calling \c -[BZRProductsManager validateTransaction:] with the transaction identifier taken from
/// the property \c bzr_transactionIdentifier of the underlying error.
- (RACSignal *)purchaseProduct:(NSString *)productIdentifier;

/// Validates the transaction specified by \c transactionId. Events can be sent on an arbitrary
/// thread.
///
/// Returns a signal that refreshes and validates the receipt. If the transaction specified by
/// \c transactionId appears in the receipt validation response, it will be finished and the
/// signal will complete. If the transaction specified by \c transactionId isn't found in the queue
/// of active transactions or if the state of the transaction is not
/// \c SKPaymentTransactionStatePurchased, the signal errs with code
/// \c BZRErrorCodeInvalidTransactionIdentifier. If validating the transaction has failed, or if a
/// transaction with the specified identifier does not appear in the receipt validation response,
/// the signal errs with an appropriate error. In that case retrying the operation may succeed.
///
/// @note If the refresh receipt was cancelled, the signal will err with an error code
/// \c BZRErrorCodeOperationCancelled. In that case retrying the operation is not recommended as it
/// is against the user intention.
- (RACSignal *)validateTransaction:(NSString *)transactionId;

/// Makes a purchase of \c quantity units of the consumable product specified by
/// \c productIdentifier. \c quantity should be at most \c 10. Events can be sent on an arbitrary
/// thread.
///
/// Returns a signal that makes a purchase of the product and completes. The signal doesn't download
/// the content of the product. To do so, \c fetchProductContent should be called. The signal errs
/// if there was an error in the purchase.
///
/// @note If the given \c quantity is invalid the signal will err with an error code
/// \c BZRErrorCodeInvalidQuantityForPurchasing.
///
/// @note If the purchase was cancelled, the signal will err with an error code
/// \c BZRErrorCodeOperationCancelled.
///
/// @note If the purchase failed and the underlying error's code is
/// \c BZRErrorCodeTransactionNotFoundInReceipt, it is possible to retry finalizing the purchase by
/// calling \c -[BZRProductsManager validateTransaction:] with the transaction identifier taken from
/// the property \c bzr_transactionIdentifier of the underlying error.
- (RACSignal *)purchaseConsumableProduct:(NSString *)productIdentifier
                                quantity:(NSUInteger)quantity;

/// Returns the current user's credit and the identifiers of consumable items that were already
/// consumed for the given \c creditType.
///
/// Returns a signal that fetches the credit and the identifiers of the consumable items that were
/// already redeemed for credit type \c creditType. On success the signal sends the credit status.
/// The signal errs if there was an error fetching the data, the error code will be
/// \c BZRErrorCodeValidatricksRequestFailed. The signal also errs when the user identifier is not
/// available, the error code will be \c BZRErrorCodeUserIdentifierNotAvailable.
- (RACSignal<BZRUserCreditStatus *> *)getUserCreditStatus:(NSString *)creditType;

/// Returns the cached user's credit and the identifiers of consumable items that were already
/// consumed for the given \c creditType. Returns \c nil if not found in cache or if there was an
/// error while reading from cache.
- (nullable BZRUserCreditStatus *)getCachedUserCreditStatus:(NSString *)creditType;

/// Gets the prices of the specified \c consumableTypes in credit units of type \c creditType.
///
/// Returns a signal that sends the required credit for each of the consumable types specified in
/// \c consumableTypes. The signal errs if there was an error fetching the data or if the price
/// of any given element of \c consumableTypes couldn't be found for the given \c creditType.
- (RACSignal<NSDictionary<NSString *, NSNumber *> *> *)getCreditPriceOfType:(NSString *)creditType
    consumableTypes:(NSSet<NSString *> *)consumableTypes;

/// Redeems all the consumable items specified by \c consumableItemsIDs with credit of type
/// \c creditType.
///
/// Returns a signal that redeems the assets specified by \c consumableItemToType with credit of
/// type \c creditType. On success the signal sends an object that specifies the credit that the
/// user has left and the status of the consumable items that were requested to be redeemed. Then
/// the signal completes. The signal errs if there was an error redeeming the consumable items or if
/// the user doesn't have enough credit to redeem the consumable items. If the user doesn't have
/// enough credit, no asset will be redeemed and the error will be populated with a property called
/// \c bzr_validatricksErrorInfo with the credit information. The signal also errs when the user
/// identifier is not available, the error code will be \c BZRErrorCodeUserIdentifierNotAvailable.
///
/// @note \c consumedItems in the returned redeem status may have \c redeemedCredit equal to \c 0 if
/// the consumable item was already redeemed.
- (RACSignal<BZRRedeemConsumablesStatus *> *)
    redeemConsumableItems:(NSDictionary<NSString *, NSString *> *)consumableItemIDToType
    ofCreditType:(NSString *)creditType;

/// Provides access to the content of the given \c product. Events can be sent on an arbitrary
/// thread.
///
/// Returns a signal that starts the fetching process. The signal returns \c LTProgress with
/// \c progress updates throughout the fetching process. When fetching is complete, the signal sends
/// an \c LTProgress with \c NSBundle as the \c result that provides access to the content and then
/// completes. If the content already exists locally, the signal completes and sends the \c NSBundle
/// immediately. The signal sends \c nil and completes if the product has no content.
/// The signal errs if there was an error while fetching the content.
- (RACSignal<LTProgress<NSBundle *> *> *)fetchProductContent:(NSString *)productIdentifier;

/// Deletes the content of the given \c product. Events can be sent on an arbitrary thread.
///
/// Returns a \c RACSignal that completes when the deletion has completed successfully. The signal
/// errs if an error occurred.
- (RACSignal *)deleteProductContent:(NSString *)productIdentifier;

/// Refreshes the receipt. This updates the subscription information and restores the list of
/// purchased products on all devices. Events can be sent on an arbitrary thread.
///
/// Returns a signal that refreshes the receipt and completes. The signal errs if the refresh has
/// failed.
///
/// @note if the user cancelled the refresh receipt operation, the signal will err with an
/// \c BZRErrorCodeOperationCancelled error code.
- (RACSignal *)refreshReceipt;

/// Returns most recently fetched list of products. This however doesn't trigger the fetching
/// process. Events can be sent on an arbitrary thread.
///
/// Returns a signal that sends the list of products as \c BZRProduct and completes. The signal
/// errs
/// if there was an error while fetching the list of products.
- (RACSignal<NSSet<BZRProduct *> *> *)productList;

/// Validates the receipt. Events can be sent on an arbitrary thread.
///
/// Returns a signal that validates the receipt. If validation is completed successfully, the latest
/// receipt from Apple is received and the receipt validation status is sent. The signal completes
/// when the validation is completed successfully. Otherwise the signal errs.
- (RACSignal<BZRReceiptValidationStatus *> *)validateReceipt;

/// Acquires all the non-subscription products that the active subscription enables. Events can be
/// sent on an arbitrary thread.
///
/// Returns a signal that acquires all the non-subscription products that the subscription enables
/// if the user has an active subscription. The signal completes after acquiring all the products.
/// The signal errs if the user doesn't have an active subscription.
- (RACSignal *)acquireAllEnabledProducts;

/// Fetches info of the products specified by \c productIdentifiers and returns them as a dictionary
/// mapping product identifiers to \c BZRProduct. Events can be sent on an arbitrary thread.
///
/// Returns a signal that fetches the info of all products specified by \c productIdentifiers and
/// sends them as a dictionary mapping identifiers to \c BZRProduct. If a product's price info
/// couldn't be fetched, it will not appear in the returned dictionary. The signal completes after
/// sending the dictionary of products. If a product identifier is missing from the product list,
/// the signal errs with error code \c BZRErrorCodeInvalidProductIdentifier and the invalid product
/// identifiers at \c bzr_productIdentifiers. If fetching the products' info encountred an error,
/// the signal errs with an error code \c BZRErrorCodeProductsMetadataFetchingFailed.
- (RACSignal<NSDictionary<NSString *, BZRProduct *> *> *)
    fetchProductsInfo:(NSSet<NSString *> *)productIdentifiers;

/// Sends transactions that were completed successfully and do not match any pending payment
/// request. Every \c SKPaymentTransaction object sent should be considered a successful purchase.
/// The signal completes when the receiver is deallocated. The signal doesn't err. Transactions can
/// be sent on an arbitrary thread.
///
/// @note The transactions sent here can be received in one of the following scenarios:
/// 1. Purchases that were initiated outside of the app (eg. subscription renewals or upgrades).
/// 2. Purchases that were initiated in previous run of the app and weren't finished yet (eg.
/// communication error at the final stages of a successful purchase / restoration or app were
/// killed before transaction was finished).
/// 3. SOON: Deferred purchases that were in pending state and were later approved and completed.
@property (readonly, nonatomic) RACSignal<SKPaymentTransaction *> *completedTransactionsSignal;

@end

NS_ASSUME_NONNULL_END
