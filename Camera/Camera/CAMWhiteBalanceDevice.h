// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device able to auto-white-balance the scene and/or manually set white
/// balance parameters.
@protocol CAMWhiteBalanceDevice <NSObject>

/// Instructs the camera to set white balance according to the current scene and then lock the
/// white balance settings.
///
/// Returned signal sends no values and completes when the new white balance is set, or errs if
/// there is a problem setting the white balance. All events are sent on an arbitrary thread.
- (RACSignal *)setSingleWhiteBalance;

/// Instructs the camera to continuously set white balance according to the current scene, updating
/// them when the device and/or subject move, until setting the white balance again.
///
/// Returned signal sends no values and completes when the new white balance is set for the first
/// time, or errs if there is a problem setting the white balance. All events are sent on an
/// arbitrary thread.
- (RACSignal *)setContinuousWhiteBalance;

/// Instructs the camera to lock the current white balance.
///
/// Returned signal sends no values and completes when white balance is locked, or errs if there is
/// a problem locking white balance. All events are sent on an arbitrary thread.
///
/// @see \c AVCaptureDevice.whiteBalanceMode.
- (RACSignal *)setLockedWhiteBalance;

/// Instructs the camera to set white balance to the given temperature and tint.
///
/// Returned signal sends a \c RACTuple of the new \c temperature and \c tint and completes when the
/// new white balance values are set, or errs if there is a problem setting the white balance. All
/// events are sent on an arbitrary thread.
- (RACSignal *)setLockedWhiteBalanceWithTemperature:(float)temperature tint:(float)tint;

@end

NS_ASSUME_NONNULL_END
