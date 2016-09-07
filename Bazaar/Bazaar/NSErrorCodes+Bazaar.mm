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
  /// Archive creation failed.
  BZRErrorCodeArchiveCreationFailed,
  /// Unachiving operaiton failed.
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
  /// Failure due to invalid underlying content fetcher parameters.
  BZRErrorCodeInvalidUnderlyingContentFetcherParameters,
  /// Failure due to unexpected underlying content fetcher parameters class.
  BZRErrorCodeUnexpectedUnderlyingContentFetcherParametersClass,
  /// Copy product's content to temporary directory has failed.
  BZRErrorCodeCopyProductContentFailed,
  /// Creation of directory has failed.
  BZRErrorCodeDirectoryCreationFailed
);

NS_ASSUME_NONNULL_END
