// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

@protocol BZRReceiptValidationStatusProvider;

/// Validator that validates the receipt periodically.
@interface BZRPeriodicReceiptValidator : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c receiptValidationProvider, used to fetch receipt validation status.
- (instancetype)initWithReceiptValidationProvider:
    (id<BZRReceiptValidationStatusProvider>)receiptValidationProvider NS_DESIGNATED_INITIALIZER;

/// Activates the periodic validation by trying to validate the receipt whenever
/// \c validateReceiptSignal fires.
- (void)activatePeriodicValidationCheck:(RACSignal *)validateReceiptSignal;

/// Deactivates the periodic validation.
- (void)deactivatePeriodicValidationCheck;

/// Sends errors when a periodic validation failed. The signal completes when the receiver is
/// deallocated. The signal doesn't err.
///
/// @return <tt>RACSignal<NSError></tt>
@property (readonly, nonatomic) RACSignal *errorsSignal;

@end

NS_ASSUME_NONNULL_END
