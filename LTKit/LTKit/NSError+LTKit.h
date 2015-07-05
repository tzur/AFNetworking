// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Error domain for LTKit.
extern NSString * const kLTKitErrorDomain;

/// Key in the \c userInfo dictionary for \c NSString value holding an error description.
extern NSString * const kLTErrorDescriptionKey;

/// Key in the \c userInfo dictionary for placing the file path related to the error.
extern NSString * const kLTFilePathErrorKey;

/// Key in the \c userInfo dictionary for \c NSNumber value holding the errno value.
extern NSString * const kLTErrnoErrorKey;

/// Key in the \c userInfo dictionary for \c NSString value holding the errno message.
extern NSString * const kLTErrnoErrorMessageKey;

/// All error codes available in LTKit.
typedef NS_ENUM(NSInteger, LTErrorCode) {
  /// Caused when an object failed to be created.
  LTErrorCodeObjectCreationFailed = 0,
  /// Caused due to an unknown error in file handling.
  LTErrorCodeFileUnknownError = 1,
  /// Caused when an expected file was not found.
  LTErrorCodeFileNotFound = 2,
  /// Caused when a target file already exists.
  LTErrorCodeFileAlreadyExists = 3,
  /// Caused when failed to read or deserialize from a file.
  LTErrorCodeFileReadFailed = 4,
  /// Caused when failed to write or serialize to a file.
  LTErrorCodeFileWriteFailed = 5,
  /// Caused when failed to remove a file.
  LTErrorCodeFileRemovalFailed = 6,
  /// Marks a POSIX error created from the current value of \c errno.
  LTErrorCodePOSIX = 7,
  /// Caused when bad file header has been read.
  LTErrorCodeBadHeader = 8
};

@interface NSError (LTKit)

/// Returns an unknown file error related to the file at the given \c path, with the given
/// underlying \c error, if provided.
+ (instancetype)lt_fileUknownErrorWithPath:(nullable NSString *)path
                           underlyingError:(nullable NSError *)error;

/// Returns an error due to a missing file at the given \c path.
+ (instancetype)lt_fileNotFoundErrorWithPath:(nullable NSString *)path;

/// Returns an error after the file at the given path already existed.
+ (instancetype)lt_fileAlreadyExistsErrorWithPath:(nullable NSString *)path;

/// Returns an error after failing to read or deserialize the file at the given \c path.
+ (instancetype)lt_fileReadFailedErrorWithPath:(nullable NSString *)path
                               underlyingError:(nullable NSError *)error;

/// Returns an error after failing to write or serialize to a file at the given \c path.
+ (instancetype)lt_fileWriteFailedErrorWithPath:(nullable NSString *)path
                                underlyingError:(nullable NSError *)error;

/// Returns an error after failing to remove the file at the given \c path, with the given
/// underlying \c error, if provided.
+ (instancetype)lt_fileRemovalFailedErrorWithPath:(nullable NSString *)path
                                  underlyingError:(nullable NSError *)error;

/// Returns an error with the current value of \c errno and its string representation.
+ (instancetype)lt_errorWithSystemErrno;

/// Returns an error after reading bad file header with its \c path and additional \c description.
+ (instancetype)lt_badFileHeaderErrorWithPath:(nullable NSString *)path
                                  description:(nullable NSString *)description;

@end

NS_ASSUME_NONNULL_END
