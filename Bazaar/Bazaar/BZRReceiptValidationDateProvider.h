// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRMultiAppReceiptValidationStatusProvider, BZRReceiptValidationStatusCache;

/// Provider that provides the time for the next receipt validation.
@protocol BZRReceiptValidationDateProvider <NSObject>

/// Date of the next validation. If this date is earlier than the current time, the validation
/// should be done immediately. \c nil if no validation is needed. KVO compliant.
@property (readonly, nonatomic, nullable) NSDate *nextValidationDate;

@end

/// Provider that calculates the next validation date to be the last validation date plus a given
/// validation interval time. For sandbox receipts the next validation date is calculated to be the
/// last validation date plus \c 150 seconds (half of the period of a monthly subscription in
/// sandbox).
@interface BZRReceiptValidationDateProvider : NSObject <BZRReceiptValidationDateProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c multiAppReceiptValidationStatusProvider that is used to provide the latest
/// receipt validation status. \c validationIntervalDays is the number of days required between
/// validations for production receipts.
- (instancetype)initWithReceiptValidationStatusProvider:
    (BZRMultiAppReceiptValidationStatusProvider *)multiAppReceiptValidationStatusProvider
    validationIntervalDays:(NSUInteger)validationIntervalDays;

@end

NS_ASSUME_NONNULL_END
