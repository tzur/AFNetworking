// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing receipt validation status.
@protocol BZRReceiptValidationStatusProvider <BZREventEmitter>

/// Returns the latest receipt validation status.
///
/// Returns a signal that delivers a \c BZRReceiptValidationStatus and completes. The signal errs if
/// there was a problem while fetching the receipt for any reason.
///
/// @return <tt>RACSignal<BZRReceiptValidationStatus></tt>
- (RACSignal *)fetchReceiptValidationStatus;

@end

NS_ASSUME_NONNULL_END
