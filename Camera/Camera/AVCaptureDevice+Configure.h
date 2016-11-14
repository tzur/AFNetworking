// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for performing operations while the receiver is locked.
@interface AVCaptureDevice (Configure)

/// Block used to perform an action and return success or failure with error. Returns \c YES if the
/// operation was successful. If it wasn't, \c errorPtr must be used to report the error.
typedef BOOL (^CAMErrorReturnBlock)(NSError **errorPtr);

/// Lock the receiver for configuration, perform \c action, and unlock the receiver. Errors while
/// locking or while performing \c action are returned in \c errorPtr. Returns \c YES if the
/// operation was successful. In any case, the receiver is unlocked before this method returns.
///
/// @note This method is not safe to be called from multiple threads concurrently (on the same
/// object), as that could lead to one thread unlocking the device before \c action ran on the
/// other thread.
///
/// @note For some properties setting order is important. E.g. \c focusMode should be set after
/// \c focusPointOfInterest else the focus point won't change (also for \c exposurePointOfInterest).
- (BOOL)cam_performWhileLocked:(CAMErrorReturnBlock)action error:(NSError **)errorPtr;

@end

NS_ASSUME_NONNULL_END
