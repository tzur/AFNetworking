// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationStatus;

/// Protocol for providing receipt validation status.
@protocol BZRReceiptValidationStatusProvider <BZREventEmitter>

/// Returns the latest receipt validation status.
///
/// Returns a signal that delivers a \c BZRReceiptValidationStatus and completes. The signal errs if
/// there was a problem while fetching the receipt for any reason.
- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus;

@end

NS_ASSUME_NONNULL_END
