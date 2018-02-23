// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPRequest, FBRHTTPResponse;

/// Adds convenience methods to convert errors generated by \c AFNetworking to \c Fiber errors.
///
/// @see NSError+Fiber, NSErrorCodes+Fiber.
@interface NSError (AFNetworkingAdapter)

/// Converts an AFNetworking to a Fiber error, i.e. an error in \c kLTErrorDomain with Fiber
/// specific error code. The given \c request and \c response will be added to the error's
/// \c userInfo dictionary. The receiver is added as the underlying error of the returned error.
- (NSError *)fbr_fiberErrorWithRequest:(nullable FBRHTTPRequest *)request
                              response:(nullable FBRHTTPResponse *)response;

@end

NS_ASSUME_NONNULL_END
