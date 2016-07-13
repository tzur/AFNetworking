// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds methods and properties to conveniently create Bazaar errors.
@interface NSError (Bazaar)

/// Creates and returns an instance of \c NSError with the given error \c code wrapping the given
/// \c exception object. Meant to be used to convert \c NSException based error reporting to
/// \c NSError based reporting.
+ (instancetype)bzr_errorWithCode:(NSInteger)code exception:(NSException *)exception;

/// Creates and returns an instance of \c NSError with the given products \c request wrapping the
/// given \c underlyingError.
+ (instancetype)bzr_errorWithCode:(NSInteger)code productsRequest:(SKProductsRequest *)request
                  underlyingError:(NSError *)underlyingError;

/// Exception object wrapped by this error.
@property (readonly, nonatomic, nullable) NSException *bzr_exception;

/// Failing products request.
@property (readonly, nonatomic, nullable) SKProductsRequest *bzr_productsRequest;

@end

NS_ASSUME_NONNULL_END
