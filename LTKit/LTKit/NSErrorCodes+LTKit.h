// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

// Defines error codes that are common across all Lightricks' products. Additional libraries and
// apps should define their business specific error codes in their own NSErrorCodes+<Product Name>.h
// file with the following structure:
//
// NS_ENUM(NSInteger) {
//   <product prefix>ErrorCodeProductID = <product ID>
// }
//
// NS_ENUM(NSInteger) {
//   <first error code name> = LTErrorCodeBase + <product prefix>ErrorCodeProductID,
//   <second error code name>,
//   // Additional error codes here.
// };
//
// The product ID should be unique across all Lightricks' products, and registered in this file.
// This will allow having unique error codes across multiple libraries and apps, while using the
// same kLTErrorDomain error domain across all generated errors.

// Currently registered products:
// LTKit -> 0.
// LTEngine -> 1.
// Enlight -> 2.

/// Basic constants for Lightricks' error domain.
NS_ENUM(NSInteger) {
  /// Offset for base of error codes, leaving three bits for source identifier.
  LTErrorCodeBaseOffset = 28,

  /// Base for all error codes in LTKit.
  LTErrorCodeBase = 0 << LTErrorCodeBaseOffset,
};

/// Product ID.
NS_ENUM(NSInteger) {
  /// Product ID of LTKit.
  LTKitErrorCodeProductID = 0
};

/// All error codes available in LTKit.
NS_ENUM(NSInteger) {
  /// Caused when an object failed to be created.
  LTErrorCodeObjectCreationFailed = LTErrorCodeBase + LTKitErrorCodeProductID,
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
  LTErrorCodeBadHeader
};
