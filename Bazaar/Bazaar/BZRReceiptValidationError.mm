// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationError.h"

NS_ASSUME_NONNULL_BEGIN

/// Receipt validation possible errors.
LTEnumImplement(NSUInteger, BZRReceiptValidationError,
  /// The receipt data sent for validation is malformed.
  BZRReceiptValidationErrorMalformedReceiptData,
  /// A remote server used for validation is not available.
  BZRReceiptValidationErrorServerIsNotAvailable,
  /// The receipt is not authentic, i.e. not signed by Apple.
  BZRReceiptValidationErrorReceiptIsNotAuthentic,
  /// The bundle identifier specified in the receipt does not match the one expected.
  BZRReceiptValidationErrorBundleIDMismatch,
  /// The device the receipt was issued for does not match the one expected.
  BZRReceiptValidationErrorDeviceIDMismatch,
  /// The receipt is Sandbox receipt and was validated as Production receipt or vice versa.
  BZRReceiptValidationErrorEnvironmentMismatch,
  /// An unknown error occurred during validation.
  BZRReceiptValidationErrorUnknown
);

NS_ASSUME_NONNULL_END
