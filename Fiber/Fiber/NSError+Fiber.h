// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPRequest, FBRHTTPResponse;

/// Key in the \c userInfo dictionary mapping to an \c FBRHTTPRequest object that the error is
/// related to.
extern NSString * const kFBRFailingHTTPRequestKey;

/// Key in the \c userInfo dictionary mapping to an \c FBRHTTPResponse object that the error is
/// related to.
extern NSString * const kFBRFailingHTTPResponseKey;

/// Adds convenience methods for easy creation of common errors in the Fiber project.
@interface NSError (Fiber)

/// Creates and returns an \c NSError with the specified \c code. \c request is added to the
/// \c userInfo dictionary with \c kFBRFailingHTTPRequestKey as its key. If \c underlyingError is
/// not \c nil it will also be added to the \c userInfo dictionary with \c NSUnderlyingErrorKey as
/// its key.
+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(FBRHTTPRequest *)request
               underlyingError:(nullable NSError *)underlyingError;

/// Creates and returns an \c NSError with the specified \c code. If \c request is not \c nil, it
/// will be added to the \c userInfo dictionary with \c kFBRFailingHTTPRequestKey as its key. If
/// \c response is not \c nil, it will be added to the \c userInfo dictionary with
/// \c kFBRFailingHTTPResponseKey as its key. If \c underlyingError is not \c nil it will also be
/// added to the \c userInfo dictionary with \c NSUnderlyingErrorKey as its key.
+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(nullable FBRHTTPRequest *)request
                  HTTPResponse:(nullable FBRHTTPResponse *)response
               underlyingError:(nullable NSError *)underlyingError;

/// HTTP request that is related to this error.
@property (readonly, nonatomic, nullable) FBRHTTPRequest *fbr_HTTPRequest;

/// HTTP response that is related to this error.
@property (readonly, nonatomic, nullable) FBRHTTPResponse *fbr_HTTPResponse;

@end

NS_ASSUME_NONNULL_END
