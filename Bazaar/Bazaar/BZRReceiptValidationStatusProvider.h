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

/// Sends messages of important events that occur throughout the receiver. The events can be
/// informational or errors. The signal completes when the receiver is deallocated. The signal
/// doesn't err.
///
/// @return <tt>RACSignal<BZREvent></tt>
@property (readonly, nonatomic) RACSignal *eventsSignal;

@end

NS_ASSUME_NONNULL_END
