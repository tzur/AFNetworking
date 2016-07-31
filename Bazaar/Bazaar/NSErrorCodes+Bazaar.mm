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
  BZRErrorCodeKeychainStorageArchivingError
);

NS_ASSUME_NONNULL_END
