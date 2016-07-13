// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMAudioDevice.h"
#import "CAMExposureDevice.h"
#import "CAMFlashDevice.h"
#import "CAMFlipDevice.h"
#import "CAMFocusDevice.h"
#import "CAMPreviewLayerDevice.h"
#import "CAMVideoDevice.h"
#import "CAMWhiteBalanceDevice.h"
#import "CAMZoomDevice.h"

NS_ASSUME_NONNULL_BEGIN

/// Stub object that implements the \c CAMDevice protocol and therefore doesn't represent a real
/// physical camera device. The protocol is implemented by:
///
/// 1. Implementing the protocol's properties as \c readwrite.
///
/// 2. Adding \c readwrite properties (mostly \c RACSignal objects) for the return values of the
/// protocol's methods.
///
/// 3. Implementing the protocol's methods by just returning the new properties from (2), while
/// ignoring the input arguments.
///
/// 4. \c initWithPreset: implementation ignores the given \c CAMDevicePreset argument.
///
/// 5. \c previewLayerPointFromDevicePoint: and \c devicePointFromPreviewLayerPoint: return the
/// given \c CGPoint.
@interface CAMDeviceStub : NSObject <CAMAudioDevice, CAMExposureDevice, CAMFlashDevice,
    CAMFlipDevice, CAMFocusDevice, CAMPreviewLayerDevice, CAMVideoDevice, CAMWhiteBalanceDevice,
    CAMZoomDevice>

#pragma mark -
#pragma mark CAMAudioDevice
#pragma mark -

/// @see CAMAudioDevice.
@property (strong, nonatomic, nullable) RACSignal *audioFrames;

#pragma mark -
#pragma mark CAMExposureDevice
#pragma mark -

/// @see CAMExposureDevice.
@property (nonatomic) float exposureOffset;

/// @see CAMExposureDevice.
@property (nonatomic) CGFloat minExposureCompensation;

/// @see CAMExposureDevice.
@property (nonatomic) CGFloat maxExposureCompensation;

/// Return value for the \c setSingleExposurePoint: method.
@property (strong, nonatomic, nullable) RACSignal *setSingleExposurePointSignal;

/// Return value for the \c setContinuousExposurePoint: method.
@property (strong, nonatomic, nullable) RACSignal *setContinuousExposurePointSignal;

/// Return value for the \c setLockedExposure method.
@property (strong, nonatomic, nullable) RACSignal *setLockedExposureSignal;

/// Return value for the \c setExposureCompensation: method.
@property (strong, nonatomic, nullable) RACSignal *setExposureCompensationSignal;

#pragma mark -
#pragma mark CAMFlashDevice
#pragma mark -

/// @see CAMFlashDevice.
@property (nonatomic) BOOL hasFlash;

/// @see CAMFlashDevice.
@property (nonatomic) BOOL flashWillFire;

/// @see CAMFlashDevice.
@property (nonatomic) AVCaptureFlashMode currentFlashMode;

/// Return value for the \c setFlashMode: method.
@property (strong, nonatomic, nullable) RACSignal *setFlashModeSignal;

#pragma mark -
#pragma mark CAMFlipDevice
#pragma mark -

/// @see CAMFlipDevice.
@property (nonatomic) CAMDeviceCamera *activeCamera;

/// @see CAMFlipDevice.
@property (nonatomic) BOOL canChangeCamera;

/// Return value for the \c setCamera: method.
@property (strong, nonatomic, nullable) RACSignal *setCameraSignal;

#pragma mark -
#pragma mark CAMFocusDevice
#pragma mark -

/// Return value for the \c setSingleFocusPoint: method.
@property (strong, nonatomic, nullable) RACSignal *setSingleFocusPointSignal;

/// Return value for the \c setContinuousFocusPoint: method.
@property (strong, nonatomic, nullable) RACSignal *setContinuousFocusPointSignal;

/// Return value for the \c setLockedFocus method.
@property (strong, nonatomic, nullable) RACSignal *setLockedFocusSignal;

/// Return value for the \c setLockedFocusPosition: method.
@property (strong, nonatomic, nullable) RACSignal *setLockedFocusPositionSignal;

#pragma mark -
#pragma mark CAMPreviewLayerDevice
#pragma mark -

/// @see CAMPreviewLayerDevice.
@property (strong, nonatomic, nullable) CALayer *previewLayer;

#pragma mark -
#pragma mark CAMVideoDevice
#pragma mark -

/// @see CAMVideoDevice.
@property (strong, nonatomic, nullable) RACSignal *videoFrames;

/// @see CAMVideoDevice.
@property (nonatomic) AVCaptureVideoOrientation videoOrientation;

/// @see CAMVideoDevice.
@property (strong, nonatomic, nullable) RACSignal *subjectAreaChanged;

/// Return value for the \c setPixelFormat: method.
@property (strong, nonatomic, nullable) RACSignal *setPixelFormatSignal;

/// Return value for the \c stillFramesWithTrigger: method.
@property (strong, nonatomic, nullable) RACSignal *stillFramesWithTriggerSignal;

#pragma mark -
#pragma mark CAMWhiteBalanceDevice
#pragma mark -

/// Return value for the \c setSingleWhiteBalance method.
@property (strong, nonatomic, nullable) RACSignal *setSingleWhiteBalanceSignal;

/// Return value for the \c setContinuousWhiteBalance method.
@property (strong, nonatomic, nullable) RACSignal *setContinuousWhiteBalanceSignal;

/// Return value for the \c setLockedWhiteBalance and \c setLockedWhiteBalanceWithTemperature:tint:
/// methods.
@property (strong, nonatomic, nullable) RACSignal *setLockedWhiteBalanceSignal;

#pragma mark -
#pragma mark CAMZoomDevice
#pragma mark -

/// @see CAMZoomDevice.
@property (nonatomic) BOOL hasZoom;

/// @see CAMZoomDevice.
@property (nonatomic) CGFloat minZoomFactor;

/// @see CAMZoomDevice.
@property (nonatomic) CGFloat maxZoomFactor;

/// @see CAMZoomDevice.
@property (nonatomic) CGFloat zoomFactor;

/// Return value for the \c setZoom and \c setZoom:rate: methods.
@property (strong, nonatomic, nullable) RACSignal *setZoomSignal;

@end

NS_ASSUME_NONNULL_END
