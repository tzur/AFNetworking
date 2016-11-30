// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device able to auto-focus on a point-of-interest and/or manually focus.
@protocol CAMFocusDevice <NSObject>

/// Instructs the camera to focus on the given device point and then lock the lens position.
///
/// Returned signal sends the new \c focusPoint and completes when the new focus is set, or errs
/// if there is a problem setting the focus. All events are sent on an arbitrary thread.
///
/// @see \c AVCaptureDevice.focusPointOfInterest.
- (RACSignal *)setSingleFocusPoint:(CGPoint)focusPoint;

/// Instructs the camera to continuously focus on the given device point, keeping it focused even
/// when the device and/or subject move, until setting the focus again.
///
/// Returned signal sends the new \c focusPoint and completes when the new focus is set for the
/// first time, or errs if there is a problem setting the focus. All events are sent on an arbitrary
/// thread.
///
/// @see \c AVCaptureDevice.focusPointOfInterest.
- (RACSignal *)setContinuousFocusPoint:(CGPoint)focusPoint;

/// Instructs the camera to lock the current focus.
///
/// Returned signal sends \c CGPointNull and completes when focus is locked, or errs if there is a
/// problem locking the focus. All events are sent on an arbitrary thread.
- (RACSignal *)setLockedFocus;

/// Instructs the camera to set the lens position to the given value. \c lensPosition should be in
/// [0,1] range and maps \c 0 to the closest focus range and \c 1 to the furthest focus range.
///
/// Returned signal sends the new \c lensPosition and completes when the new focus is set, or errs
/// if there is a problem setting the focus. All events are sent on an arbitrary thread.
///
/// @see \c AVCaptureDevice.lensPosition.
- (RACSignal *)setLockedFocusPosition:(CGFloat)lensPosition;

@end

NS_ASSUME_NONNULL_END
