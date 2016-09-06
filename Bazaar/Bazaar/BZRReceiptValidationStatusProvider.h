// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing receipt validation status.
@protocol BZRReceiptValidationStatusProvider <NSObject>

/// Returns the latest receipt validation status.
///
/// Returns a signal that delivers a \c BZRReceiptValidationStatus and completes. The signal errs if
/// there was a problem while fetching the receipt for any reason.
///
/// @return <tt>RACSignal<BZRReceiptValidationStatus></tt>
- (RACSignal *)fetchReceiptValidationStatus;

/// Sends non-critical errors as values. The signal completes when the receiver is deallocated. The
/// signal doesn't err.
///
/// @return <tt>RACSignal<NSError></tt>
@property (readonly, nonatomic) RACSignal *nonCriticalErrorsSignal;

@end

NS_ASSUME_NONNULL_END
