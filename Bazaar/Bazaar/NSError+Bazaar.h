// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Adds methods and properties to conveniently create Bazaar errors.
@interface NSError (Bazaar)

/// Creates and returns an instance of \c NSError with the given error \c code wrapping the given
/// \c exception object. Meant to be used to convert \c NSException based error reporting to
/// \c NSError based reporting.
+ (instancetype)bzr_errorWithCode:(NSInteger)code exception:(NSException *)exception;

/// Exception object wrapped by this error.
@property (readonly, nonatomic, nullable) NSException *bzr_exception;

@end

NS_ASSUME_NONNULL_END
