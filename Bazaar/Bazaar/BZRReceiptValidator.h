// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationParameters, RACSignal;

/// Protocol for application receipt validators.
@protocol BZRReceiptValidator <NSObject>

/// Validates the authenticity and the integrity of the receipt provided in \c parameters. The
/// validator will validate that the receipt was issued for the application specified by
/// \c parameters.applicationBundleId. If \c parameters.deviceId is not \c nil the validator may use
/// it to validate that the receipt was issued for a device with the same ID.
/// Returns a signal that sends a single \c BZRReceiptValidationResponse and then completes or errs
/// if failed to complete the receipt validation.
///
/// @return <tt>RACSignal<BZRReceiptValidationResponse *></tt>
- (RACSignal *)validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters;

@end

NS_ASSUME_NONNULL_END
