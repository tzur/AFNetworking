// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of Bazaar.
  BazaarErrorCodeProductID = 10
};

/// All error codes produced by Bazaar.
LTErrorCodesDeclare(BazaarErrorCodeProductID,
  /// The process of application receipt validation has failed.
  BZRErrorCodeReceiptValidationFailed,
  /// Failure during products metadata fetching.
  BZRErrorCodeProductsMetadataFetchingFailed,
  /// Failure during receipt refreshing.
  BZRErrorCodeReceiptRefreshFailed,
  /// Deserialization of a model instance from JSON dictionary has failed.
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
  /// Creation of an archive file has failed.
  BZRErrorCodeArchiveCreationFailed,
  /// Unarchiving of an archive file failed.
  BZRErrorCodeUnarchivingFailed,
  /// Archiving / unarchiving operation was cancelled.
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
  /// Transaction that has completed but was not found in the receipt.
  BZRErrorCodeTransactionNotFoundInReceipt,
  /// Received an invalid transaction identifier.
  BZRErrorCodeInvalidTransactionIdentifier,
  /// Received request to purchase product that is not valid for purchasing.
  BZRErrorCodeInvalidProductForPurchasing,
  /// Received request to acquire all products for a user that's not a subscriber.
  BZRErrorCodeAcquireAllRequestedForNonSubscriber,
  /// Failure while moving a file or a directory.
  BZRErrorCodeMoveItemFailed,
  /// Fetching of product content has failed.
  BZRErrorCodeFetchingProductContentFailed,
  /// Fetching content has failed due to a version mismatch between a product and its downloaded
  /// content.
  BZRErrorCodeFetchedContentMismatch,
  /// Error that is caused by an operation that was cancelled.
  BZRErrorCodeOperationCancelled,
  /// Error that is caused by a purchase that is not allowed.
  BZRErrorCodePurchaseNotAllowed,
  /// Restoring purchases operation has failed.
  BZRErrorCodeRestorePurchasesFailed,
  /// Service name was not found while trying to store/retrieve data from storage.
  BZRErrorCodeServiceNameNotFound,
  /// Trying to purchase a product with an invalid quantity.
  BZRErrorCodeInvalidQuantityForPurchasing,
  /// Request to Validatricks server has failed.
  BZRErrorCodeValidatricksRequestFailed,
  /// Failure because the user identifier couldn't be retrieved.
  BZRErrorCodeUserIdentifierNotAvailable
);

NS_ASSUME_NONNULL_END
