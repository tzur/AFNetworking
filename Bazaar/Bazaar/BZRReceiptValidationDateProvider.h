// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@class BZRAggregatedReceiptValidationStatusProvider, BZRReceiptValidationStatusCache;

/// Provider that provides the time for the next receipt validation.
@protocol BZRReceiptValidationDateProvider <NSObject>

/// Date of the next validation. If this date is earlier than the current time, the validation
/// should be done immediately. \c nil if no validation is needed. KVO compliant.
@property (readonly, nonatomic, nullable) NSDate *nextValidationDate;

@end

/// Provider that calculates the next validation date to be the last validation date plus half of
/// the cache TTL. For sandbox receipts the next validation date is calculated to be the last
/// validation date plus \c 150 seconds (half of the period of a monthly subscription in sandbox).
@interface BZRReceiptValidationDateProvider : NSObject <BZRReceiptValidationDateProvider>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c receiptValidationStatusCache which is used to fetch the earliest validation
/// date. \c receiptValidationStatusProvider is used to provide the latest receipt validation
/// status. \c bundledApplicationsIDs is the set of applications for which validation will be
/// performed. \c cachedEntryDaysToLive is used to calculate the validation period.
- (instancetype)initWithReceiptValidationStatusCache:
    (BZRReceiptValidationStatusCache *)receiptValidationStatusCache
    receiptValidationStatusProvider:(BZRAggregatedReceiptValidationStatusProvider *)
    receiptValidationStatusProvider
    bundledApplicationsIDs:(NSSet<NSString *> *)bundledApplicationsIDs
    cachedEntryDaysToLive:(NSUInteger)cachedEntryDaysToLive NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
