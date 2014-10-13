// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Error domain for LTKit.
extern NSString * const kLTKitErrorDomain;

/// Key for placing internal error message in the \c userInfo dictionary of an \c NSError object.
extern NSString * const kLTInternalErrorMessageKey;

/// All error codes available in LTKit.
typedef NS_ENUM(NSInteger, LTErrorCode) {
  /// Caused when an object failed to be created.
  LTErrorCodeObjectCreationFailed = 0,
  /// Caused due to error in file handling.
  LTErrorFileError = 1
};
