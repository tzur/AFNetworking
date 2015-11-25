// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+LTKit.h"

/// All error codes available in LTKit.
LTErrorCodesImplement(LTKitErrorCodeProductID,
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
  LTErrorCodeNullValueGiven
);
