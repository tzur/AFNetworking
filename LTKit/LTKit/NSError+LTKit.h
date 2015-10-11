// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+LTKit.h"

NS_ASSUME_NONNULL_BEGIN

/// Error domain for Lightricks. This domain should be used across all Lightricks products.
extern NSString * const kLTErrorDomain;

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

/// Returns the system error message related to the given \c error. \c error is usually the current
/// \c errno value.
NSString *LTSystemErrorMessageForError(int error);

@interface NSError (LTKit)

/// Creates an error with Lightricks' domain and given error code.
+ (instancetype)lt_errorWithCode:(NSInteger)code;

/// Creates an error with Lightricks' domain, given error code and \c userInfo dictionary.
+ (instancetype)lt_errorWithCode:(NSInteger)code userInfo:(nullable NSDictionary *)userInfo;

/// Creates an error with Lightricks' domain, given error code and the given underlying error.
+ (instancetype)lt_errorWithCode:(NSInteger)code underlyingError:(NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code and the given underlying errors.
+ (instancetype)lt_errorWithCode:(NSInteger)code
                underlyingErrors:(NSArray<NSError *> *)underlyingErrors;

/// Creates an error with Lightricks' domain, given error code and the given error description.
+ (instancetype)lt_errorWithCode:(NSInteger)code description:(NSString *)description;

/// Creates an error with Lightricks' domain, given error code and the given related file path.
+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path;

/// Creates an error with Lightricks' domain, given error code, related file path and underlying
/// error.
+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path
                 underlyingError:(NSError *)underlyingError;

/// Creates an error with Lightricks' domain, given error code, related file path and underlying
/// errors.
+ (instancetype)lt_errorWithCode:(NSInteger)code path:(NSString *)path
                underlyingErrors:(NSArray<NSError *> *)underlyingErrors;

/// Creates an error with Lightricks' domain, given error code and the given related URL.
+ (instancetype)lt_errorWithCode:(NSInteger)code url:(NSURL *)url;

/// Creates an error with Lightricks' domain, given error code, related URL and underlying error.
+ (instancetype)lt_errorWithCode:(NSInteger)code url:(NSURL *)url
                 underlyingError:(NSError *)underlyingError;

/// Returns an error with the current system error and its string representation. An error will be
/// returned even if the current system error variable indicates that there's no error.
+ (instancetype)lt_errorWithSystemError;

/// Underlying error.
@property (readonly, nonatomic, nullable) NSError *lt_underlyingError;

/// Underlying errors. This is similar to \c lt_underlyingError but contains a collection instead of
/// a single error.
@property (readonly, nonatomic, nullable) NSArray<NSError *> *lt_underlyingErrors;

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
