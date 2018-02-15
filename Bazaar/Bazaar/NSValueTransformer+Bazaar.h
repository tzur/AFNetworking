// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@interface NSValueTransformer (Bazaar)

/// Returns a bi-directional value transformer that transforms \c NSNumber objects boxing an
/// \c NSTimeInterval that specifies a number of seconds since 1970 to a matching \c NSDate object
/// and vice versa.
+ (NSValueTransformer *)bzr_timeIntervalSince1970ValueTransformer;

/// Returns a bi-directional value transformer that transforms \c NSNumber objects that specifies
/// the number of milli-seconds elapsed since 1970 to a matching \c NSDate object and vice versa.
///
/// @note Unlike \c bzr_timeIntervalSince1970ValueTransformer this transformer expects and produces
/// \c NSNumber containing time in milli-seconds and not seconds.
+ (NSValueTransformer *)bzr_millisecondsDateTimeValueTransformer;

/// Returns a uni-directional value transformer that transforms \c Validatricks error codes to
/// \c BZRReceiptValidationError values.
+ (NSValueTransformer *)bzr_validatricksErrorValueTransformer;

/// Returns a bi-direction value transformers that transforms \c receipt environment values to
/// \c BZRReceiptEnvironment values and vice versa.
+ (NSValueTransformer *)bzr_validatricksReceiptEnvironmentValueTransformer;

/// Returns a reversible transformer that converts an input \c NSString to its \c id<LTEnum>
/// instance (by initializing the enum with its name).
///
/// If the given \c enumClass is \c nil or it does not conform to \c LTEnum protocol, an
/// \c NSInvalidArgumentException will be raised.
+ (NSValueTransformer *)bzr_enumNameTransformerForClass:(Class)enumClass;

@end

NS_ASSUME_NONNULL_END
