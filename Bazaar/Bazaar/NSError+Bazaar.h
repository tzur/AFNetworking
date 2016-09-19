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

/// Creates and returns an instance of \c NSError with the given error \c code. \c arhivePath
/// is the path to the archive file that the failing archiving operation was executed on.
/// \c failingItemPath is the path to the file or directory that caused the failure.
/// \c underlyingError may be provided to specify an underlyign error. A custom error \c description
/// may be provided.
+ (instancetype)bzr_errorWithCode:(NSInteger)code
                      archivePath:(NSString *)archivePath
           failingArchiveItemPath:(nullable NSString *)failingItemPath
                  underlyingError:(nullable NSError *)underlyingError
                      description:(nullable NSString *)description;

/// Creates and returns an instance of \c NSError with the given error \c code wrapping the given
/// \c transaction.
+ (instancetype)bzr_errorWithCode:(NSInteger)code transaction:(SKPaymentTransaction *)transaction;

/// Exception object wrapped by this error.
@property (readonly, nonatomic, nullable) NSException *bzr_exception;

/// Failing products request.
@property (readonly, nonatomic, nullable) SKProductsRequest *bzr_productsRequest;

/// Path of the archive file that a failing archiving operation was executed on.
@property (readonly, nonatomic, nullable) NSString *bzr_archivePath;

/// Path of the failing item that was archived or unarchived.
@property (readonly, nonatomic, nullable) NSString *bzr_failingItemPath;

/// Failed transaction wrapped by this error.
@property (readonly, nonatomic, nullable) SKPaymentTransaction *bzr_transaction;

@end

NS_ASSUME_NONNULL_END
