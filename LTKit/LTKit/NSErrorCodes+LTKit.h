// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+Macros.h"

// Defines error codes that are common across all Lightricks' products. Additional libraries and
// apps should define their business specific error codes in their own NSErrorCodes+<Product Name>.h
// file with the following structure:
//
// NS_ENUM(NSInteger) {
//   <product prefix>ErrorCodeProductID = <Product ID>
// }
//
// LTErrorCodesDeclare(<product prefix>ErrorCodeProductID,
//   <first error code name>,
//   <second error code name>,
//   // Additional error codes here
// );
//
// Additionally, create an NSErrorCodes+<Product Name>.mm file with the implementation:
//
// LTErrorCodesImplement(<product prefix>ErrorCodeProductID,
//   <first error code name>,
//   <second error code name>,
//   // Additional error codes here.
// );
//
// The product ID should be unique across all Lightricks' products, and registered in this file.
// This will allow having unique error codes across multiple libraries and apps, while using the
// same kLTErrorDomain error domain across all generated errors.

// Currently registered products:
// LTKit -> 0.
// LTEngine -> 1.
// Enlight -> 2.
// Photons -> 3.
// Wireframes -> 4.
// Blueprints -> 5.
// Camera -> 6.
// CameraUI -> 7.
// Facetune -> 8.
// Fiber -> 9.
// Bazaar -> 10.
// Enlight Video -> 11.
// Enlight Photos -> 12.
// Laboratory -> 13.
// Shopix -> 14.
// TinCan -> 15.
// Intelligence -> 16.
// Phoenix -> 17.
// Antares -> 18.

/// Defines error codes for a given product ID. The first given parameter is the product ID or a
/// constant representing it. Error codes follow. Example:
/// @code
/// LTErrorCodesDeclare(LTKitErrorCodeProductID,
///                     LTErrorCodeFoo,
///                     LTErrorCodeBar,
///                     LTErrorCodeBaz);
/// @endcode
///
/// Error codes are defined globally, even if their scope is limited. Avoid defining an error code
/// with a similar name twice.
#define LTErrorCodesDeclare(PRODUCT_ID, ...) \
  _LTErrorCodesDeclare(PRODUCT_ID, __VA_ARGS__)

/// Implements and registers the error codes for a given product ID. The first given parameter is
/// the product ID or a constant representing it. Error codes follow. Example:
/// @code
/// LTErrorCodesImplement(LTKitErrorCodeProductID,
///                       LTErrorCodeFoo,
///                       LTErrorCodeBar,
///                       LTErrorCodeBaz);
/// @endcode
///
/// Error codes are defined globally, even if their scope is limited. Avoid defining an error code
/// with a similar name twice.
#define LTErrorCodesImplement(PRODUCT_ID, ...) \
  _LTErrorCodesImplement(PRODUCT_ID, __VA_ARGS__)

/// Basic constants for Lightricks' error domain.
NS_ENUM(NSInteger) {
  /// Offset for base of error codes, leaving 8 bits for product identifier.
  LTErrorCodeBaseOffset = 24,
};

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of LTKit.
  LTKitErrorCodeProductID = 0
};

/// All error codes available in LTKit.
LTErrorCodesDeclare(LTKitErrorCodeProductID,
  /// Caused when an object failed to be created.
  LTErrorCodeObjectCreationFailed,
  /// Caused due to an unknown error in file handling.
  LTErrorCodeFileUnknownError,
  /// Caused when an expected file was not found.
  LTErrorCodeFileNotFound,
  /// Caused when a target file already exists.
  LTErrorCodeFileAlreadyExists,
  /// Caused when failed to read or deserialize from a file.
  LTErrorCodeFileReadFailed,
  /// Caused when failed to write or serialize to a file.
  LTErrorCodeFileWriteFailed,
  /// Caused when failed to remove a file.
  LTErrorCodeFileRemovalFailed,
  /// Marks a POSIX error created from the current value of \c errno.
  LTErrorCodePOSIX,
  /// Caused when bad file header has been read.
  LTErrorCodeBadHeader,
  /// Caused when a nonnull value was expected but null was provided.
  LTErrorCodeNullValueGiven,
  /// Caused when the compression process has failed.
  LTErrorCodeCompressionFailed,
  /// Caused when a decryption of encrypted data has failed.
  LTErrorCodeDecryptionFailed,
  /// Caused when a decoding of hex string has failed.
  LTErrorCodeHexDecodingFailed,
  /// Caused when an invalid argument has been passed to a method.
  LTErrorCodeInvalidArgument,
  /// Caused when an exception is raised, caught and converted to error.
  LTErrorCodeExceptionRaised,
  /// Caused when an encryption operation failed.
  LTErrorCodeEncryptionFailed
);
