// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

/// All error codes produced by Bazaar.
LTErrorCodesImplement(BazaarErrorCodeProductID,
  /// The process of application receipt validation has failed.
  BZRErrorCodeReceiptValidationFailed,
  /// Failure during products metadata fetching.
  BZRErrorCodeProductsMetadataFetchingFailed,
  /// Failure during receipt refreshing.
  BZRErrorCodeReceiptRefreshFailed,
  /// Deserilization of a model instance from JSON dictionary has failed.
  BZRErrorCodeModelJSONDeserializationFailed,
  /// Deserialization of a JSON object from raw data has failed.
  BZRErrorCodeJSONDataDeserializationFailed,
  /// Serialization of a model instance to JSON dictionary has failed.
  BZRErrorCodeModelJSONSerializationFailed,
  /// Failure during data archiving.
  BZRErrorCodeKeychainStorageArchivingError,
  /// Loading data from storage has failed.
  BZRErrorCodeLoadingFromKeychainStorageFailed,
  /// Storing data to storage has failed.
  BZRErrorCodeStoringToKeychainStorageFailed,
  /// Archive creation failed.
  BZRErrorCodeArchiveCreationFailed,
  /// Unarchiving operation failed.
  BZRErrorCodeUnarchivingFailed,
  /// Archiving operation was cancelled.
  BZRErrorCodeArchivingCancelled,
  /// Archiving of an item, a file or a directory, has failed.
  BZRErrorCodeItemArchivingFailed,
  /// Retrieval of file attributes has failed.
  BZRErrorCodeFileAttributesRetrievalFailed,
  /// Directory enumeration failed.
  BZRErrorCodeDirectoryEnumrationFailed,
  /// Requested content fetcher is not registered.
  BZRErrorCodeProductContentFetcherNotRegistered,
  /// Failure due to invalid content fetcher parameters.
  BZRErrorCodeInvalidContentFetcherParameters,
  /// Failure due to unexpected content fetcher parameters class.
  BZRErrorCodeUnexpectedContentFetcherParametersClass,
  /// Copy product's content to temporary directory has failed.
  BZRErrorCodeCopyProductContentFailed,
  /// Creation of directory has failed.
  BZRErrorCodeDirectoryCreationFailed,
  /// Purchase of a product has failed.
  BZRErrorCodePurchaseFailed,
  /// Received a transaction that isn't associated with a payment.
  BZRErrorCodeUnhandledTransactionReceived,
  /// Received a purchase request with invalid product identifier.
  BZRErrorCodeInvalidProductIdentifier,
  /// Fetching of product list has failed.
  BZRErrorCodeFetchingProductListFailed,
  /// The receipt validation has failed during the periodic check.
  BZRErrorCodePeriodicReceiptValidationFailed,
  /// Loading of file has failed.
  BZRErrorCodeLoadingFileFailed,
  /// Product was purchased successfully but not found in the receipt.
  BZRErrorCodePurchasedProductNotFoundInReceipt,
  /// Received request to purchase product that is not valid for purchasing.
  BZRErrorCodeInvalidProductForPurchasing,
  /// Received request to acquire all products for a user that's not a subscriber.
  BZRErrorCodeAcquireAllRequestedForNonSubscriber,
  /// Failure while moving a file or a directory.
  BZRErrorCodeMoveItemFailed,
  /// The subscription that the user owns does not appear in the product list
  BZRErrorCodeSubscriptionNotFoundInProductList,
  /// Fetching of product content has failed.
  BZRErrorCodeFetchingProductContentFailed,
  /// Fetching content has failed due to a version mismatch between a product and its downloaded
  /// content.
  BZRErrorCodeFetchedContentMismatch,
  /// Error that is caused by an operation that was cancelled.
  BZRErrorCodeOperationCancelled,
  /// Restoring purchases operation has failed.
  BZRErrorCodeRestorePurchasesFailed,
  /// Service name was not found while trying to store/retrieve data from storage.
  BZRErrorCodeServiceNameNotFound
);

NS_ASSUME_NONNULL_END
