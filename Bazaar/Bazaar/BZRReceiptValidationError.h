// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

/// Receipt validation possible errors.
LTEnumDeclare(NSUInteger, BZRReceiptValidationError,
  /// The receipt data sent for validation is malformed.
  BZRReceiptValidationErrorMalformedReceiptData,
  /// The receipt is not authentic, i.e. not signed by Apple.
  BZRReceiptValidationErrorReceiptIsNotAuthentic,
  /// The bundle identifier specified in the receipt does not match the one expected.
  BZRReceiptValidationErrorBundleIDMismatch,
  /// The device the receipt was issued for does not match the one expected.
  BZRReceiptValidationErrorDeviceIDMismatch,
  /// The receipt is Sandbox receipt and was validated as Production receipt or vice versa.
  BZRReceiptValidationErrorEnvironmentMismatch,
  /// No receipt associated with the given user ID was found.
  BZRReceiptValidationErrorMissingReceipt,
  /// An unknown error occurred during validation.
  BZRReceiptValidationErrorUnknown
);

NS_ASSUME_NONNULL_END
