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
///
/// @note The value <tt>[0.5, 0.5]</tt> is a special value, resulting in exposure being measured
/// over the entire frame. For all other values, exposure is measured at that point only. See
/// https://stackoverflow.com/a/14088534/1074055 for reference.
- (RACSignal *)setSingleExposurePoint:(CGPoint)exposurePoint;

/// Instructs the camera to continuously set exposure according to the given device point, updating
/// them when the device and/or subject move, until setting the exposure again.
///
/// Returned signal sends the new \c exposurePoint and completes when the new exposure is set for
/// the first time, or errs if there is a problem setting the exposure. All events are sent on an
/// arbitrary thread.
///
/// @see \c AVCaptureDevice.exposurePointOfInterest.
///
/// @note The value <tt>[0.5, 0.5]</tt> is a special value, resulting in exposure being measured
/// over the entire frame. For all other values, exposure is measured at that point only. See
/// https://stackoverflow.com/a/14088534/1074055 for reference.
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

/// Instructs the camera to enter the Custom exposure mode and lock the exposure duration on
/// \c exposureDuration. \c exposureDuration should be in the range
/// <tt>[minExposureDuration, maxExposureDuration]</tt>.
///
/// Returned signal sends the new exposure duration value and completes when it is set, or errs
/// if there is a problem setting the exposure duration. All events are sent on an arbitrary thread.
- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration;

/// Instructs the camera to enter the Custom exposure mode and lock the ISO on \c ISO. \c ISO should
/// be in the range <tt>[minISO, maxISO]</tt>.
///
/// Returned signal sends the new ISO value and completes when it is set, or errs if there is a
/// problem setting the ISO. All events are sent on an arbitrary thread.
- (RACSignal *)setManualExposureWithISO:(float)ISO;

/// Instructs the camera to enter the Custom exposure mode and lock the exposure duration on
/// \c exposureDuration and ISO on \c ISO.
///
/// Returned signal sends the new exposure compensation value and completes when it is set, or errs
/// if there is a problem setting the exposure. All events are sent on an arbitrary thread.
- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration andISO:(float)ISO;

/// Difference between the current scene's exposure metering and the current exposure settings, in
/// EV units.
@property (readonly, nonatomic) float exposureOffset;

/// Minimum exposure compensation value supported by the camera.
@property (readonly, nonatomic) CGFloat minExposureCompensation;

/// Maximum exposure compensation value supported by the camera.
@property (readonly, nonatomic) CGFloat maxExposureCompensation;

/// Exposure duration. Affects both video stream (exposure and frame rate) and still photos.
@property (readonly, nonatomic) NSTimeInterval exposureDuration;

/// Minimal valid value for \c exposureDuration.
@property (readonly, nonatomic) NSTimeInterval minExposureDuration;

/// Maximal valid value for \c exposureDuration.
@property (readonly, nonatomic) NSTimeInterval maxExposureDuration;

/// ISO value. Affects both video stream and still photos.
@property (readonly, nonatomic) float ISO;

/// Minimal valid value for \c ISO.
@property (readonly, nonatomic) float minISO;

/// Maximal valid value for \c ISO.
@property (readonly, nonatomic) float maxISO;

@end

NS_ASSUME_NONNULL_END
