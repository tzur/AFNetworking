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
  /// Deserilization of a model instance from JSON dictionary has failed.
  BZRErrorCodeModelJSONDeserializationFailed,
  /// Deserialization of a JSON object from raw data has failed.
  BZRErrorCodeJSONDataDeserializationFailed,
  /// Invalid keychain arguments.
  BZRErrorCodeKeychainStorageInvalidArguments,
  /// Failure during keychain access.
  BZRErrorCodeKeychainStorageAccessFailed,
  /// Unexpected failure occured.
  BZRErrorCodeKeychainStorageUnexpectedFailure,
  /// Failure during data conversion.
  BZRErrorCodeKeychainStorageConversionFailed,
  /// Failure during data archiving.
  BZRErrorCodeKeychainStorageArchivingError,
  /// Loading data from storage has failed.
  BZRErrorCodeLoadingDataFromStorageFailed,
  /// Storing data to storage has failed.
  BZRErrorCodeStoringDataToStorageFailed,
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
  /// Received a purchase request with invalid product identifer.
  BZRErrorCodeInvalidProductIdentifer,
  /// Fetching of product list has failed.
  BZRErrorCodeFetchingProductListFailed,
  /// The receipt validation has failed during the periodic check.
  BZRErrorCodePeriodicReceiptValidationFailed
);

NS_ASSUME_NONNULL_END
