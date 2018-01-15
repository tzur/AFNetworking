// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREventEmitter.h"

NS_ASSUME_NONNULL_BEGIN

@class BZRReceiptValidationStatus;

/// Protocol for providing receipt validation status.
@protocol BZRReceiptValidationStatusProvider <BZREventEmitter>

/// Returns the latest receipt validation status of the application given by \c applicationBundleID.
///
/// Returns a signal that delivers a \c BZRReceiptValidationStatus of the application specified by
/// the given \c applicationBundleID and completes. The signal errs if there was a problem while
/// fetching the receipt for any reason.
- (RACSignal<BZRReceiptValidationStatus *> *)fetchReceiptValidationStatus:
    (NSString *)applicationBundleID;

@end

NS_ASSUME_NONNULL_END
