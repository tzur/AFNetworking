// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Error domain for LTKit.
extern NSString * const kLTKitErrorDomain;

/// Key in the \c userInfo dictionary for \c NSArray of \c NSError objects holding the underlying
/// errors causing this error.
extern NSString * const kLTUnderlyingErrorsKey;

/// Key in the \c userInfo dictionary for \c NSString value holding an non-localized error
/// description. This description should not be shown to the user.
extern NSString * const kLTErrorDescriptionKey;

/// Key in the \c userInfo dictionary for \c NSNumber value holding the system error value.
extern NSString * const kLTSystemErrorKey;

/// Key in the \c userInfo dictionary for \c NSString value holding the system error message.
extern NSString * const kLTSystemErrorMessageKey;

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

/// Creates an error with LTKit's domain and given error code.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code;

/// Creates an error with LTKit's domain, given error code and \c userInfo dictionary.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code userInfo:(nullable NSDictionary *)userInfo;

/// Creates an error with LTKit's domain, given error code and the given underlying error.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code underlyingError:(NSError *)underlyingError;

/// Creates an error with LTKit's domain, given error code and the given underlying errors.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code underlyingErrors:(NSArray *)underlyingErrors;

/// Creates an error with LTKit's domain, given error code and the given error description.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code description:(NSString *)description;

/// Creates an error with LTKit's domain, given error code and the given related file path.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code path:(NSString *)path;

/// Creates an error with LTKit's domain, given error code, related file path and underlying error.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code path:(NSString *)path
                 underlyingError:(NSError *)underlyingError;

/// Creates an error with LTKit's domain, given error code and the given related URL.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code url:(NSURL *)url;

/// Creates an error with LTKit's domain, given error code, related URL and underlying error.
+ (instancetype)lt_errorWithCode:(LTErrorCode)code url:(NSURL *)url
                 underlyingError:(NSError *)underlyingError;

/// Returns an error with the current system error and its string representation. An error will be
/// returned even if the current system error variable indicates that there's no error.
+ (instancetype)lt_errorWithSystemError;

/// Underlying error.
@property (readonly, nonatomic, nullable) NSError *lt_underlyingError;

/// Underlying errors.
@property (readonly, nonatomic, nullable) NSArray *lt_underlyingErrors;

/// Non-localized error description. This description should not be shown to the user.
@property (readonly, nonatomic, nullable) NSString *lt_description;

/// Path related to the error.
@property (readonly, nonatomic, nullable) NSString *lt_path;

/// URL related to the error.
@property (readonly, nonatomic, nullable) NSURL *lt_url;

/// System error value.
@property (readonly, nonatomic, nullable) NSNumber *lt_systemError;

/// System error message.
@property (readonly, nonatomic, nullable) NSString *lt_systemErrorMessage;

@end

NS_ASSUME_NONNULL_END
