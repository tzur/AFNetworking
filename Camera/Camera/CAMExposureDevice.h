// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device able to auto-expose on a point-of-interest and/or manually set
/// exposure parameters.
@protocol CAMExposureDevice <NSObject>

/// Instructs the camera to set exposure according to the given device point and then lock the
/// exposure settings.
///
/// Returned signal sends the new \c exposurePoint and completes when the new exposure is set, or
/// errs if there is a problem setting the exposure. All events are sent on an arbitrary thread.
///
/// @see \c AVCaptureDevice.exposurePointOfInterest.
- (RACSignal *)setSingleExposurePoint:(CGPoint)exposurePoint;

/// Instructs the camera to continuously set exposure according to the given device point, updating
/// them when the device and/or subject move, until setting the exposure again.
///
/// Returned signal sends the new \c exposurePoint and completes when the new exposure is set for
/// the first time, or errs if there is a problem setting the exposure. All events are sent on an
/// arbitrary thread.
///
/// @see \c AVCaptureDevice.exposurePointOfInterest.
- (RACSignal *)setContinuousExposurePoint:(CGPoint)exposurePoint;

/// Instructs the camera to lock the current exposure.
///
/// Returned signal sends \c CGPointNull and completes when exposure is locked, or errs if there is
/// a problem locking the exposure. All events are sent on an arbitrary thread.
- (RACSignal *)setLockedExposure;

/// Instructs the camera to over- or under- expose frames. \c value will be added to the scene
/// exposure metering before determining the exposure settings to use. Positive values result in
/// over-exposed images. \c value is in EV units. \c value should be in the range
/// <tt>[minExposureCompensation, maxExposureCompensation]</tt>.
///
/// Returned signal sends the new exposure compensation value and completes when it is set, or errs
/// if there is a problem setting the exposure. All events are sent on an arbitrary thread.
- (RACSignal *)setExposureCompensation:(float)value;

/// Difference between the current scene's exposure metering and the current exposure settings, in
/// EV units.
@property (readonly, nonatomic) float exposureOffset;

/// Minimum exposure compensation value supported by the camera.
@property (readonly, nonatomic) CGFloat minExposureCompensation;

/// Maximum exposure compensation value supported by the camera.
@property (readonly, nonatomic) CGFloat maxExposureCompensation;

@end

NS_ASSUME_NONNULL_END
