// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@interface NSValueTransformer (Validatricks)

/// Returns a bi-directional value transformer that transforms \c NSNumber objects boxing an
/// \c NSTimeInterval that specifies a number of seconds since 1970 to a matching \c NSDate object
/// and vice versa.
+ (NSValueTransformer *)bzr_timeIntervalSince1970ValueTransformer;

/// Returns a bi-directional value transformer that transforms \c NSNumber objects that specifies
/// the number of milli-seconds elapsed since 1970 to a matching \c NSDate object and vice versa.
///
/// @note Unlike \c bzr_timeIntervalSince1970ValueTransformer this transformer expects and produces
/// \c NSNumber containing time in milli-seconds and not seconds.
+ (NSValueTransformer *)bzr_validatricksDateTimeValueTransformer;

/// Returns a uni-directional value transformer that transforms \c Validatricks error codes to
/// \c BZRReceiptValidationError values.
+ (NSValueTransformer *)bzr_validatricksErrorValueTransformer;

/// Returns a bi-direction value transformers that transforms \c Validatricks receipt environment
/// values to \c BZRReceiptEnvironment values and vice versa.
+ (NSValueTransformer *)bzr_validatricksReceiptEnvironmentValueTransformer;

@end

NS_ASSUME_NONNULL_END
