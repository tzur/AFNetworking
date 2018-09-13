// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fake \c AVCaptureDevice to be used in testing. To use, explicitly cast to \c AVCaptureDevice
/// (or \c id).
///
/// Starting with iOS 11, Apple have made it harder to directly subclass \c AVCaptureDevice.
/// Therefore, this class contains some properties that are needed so compilation and linkage will
/// still work.
@interface CAMFakeAVCaptureDevice : NSObject

/// Error to return in \c lockForConfiguration:. If \c nil, \c lockForConfiguration: will succeed.
@property (strong, nonatomic) NSError *lockError;

/// Set to \c YES after \c lockForConfiguration: is called.
@property (readonly, nonatomic) BOOL didLock;

/// Set to \c YES after \c unlockForConfiguration is called.
@property (readonly, nonatomic) BOOL didUnlock;

/// Set to \c YES when \c unlockForConfiguration is called, and \c lockForConfiguration: was called
/// before.
@property (readonly, nonatomic) BOOL didUnlockWhileLocked;

/// Media types the receiver will report to "have", when queried using \c hasMediaType:.
@property (copy, nonatomic) NSArray<NSString *> *mediaTypes;

/// Value to return in \c isFocusModeSupported:.
@property (nonatomic) BOOL focusModeSupported;

/// Override to allow setting this property.
@property (nonatomic) BOOL focusPointOfInterestSupported;

/// Value to return in \c isExposureModeSupported:.
@property (nonatomic) BOOL exposureModeSupported;

/// Override to allow setting this property.
@property (nonatomic) BOOL exposurePointOfInterestSupported;

/// Override to allow setting this property.
@property (nonatomic) float minExposureTargetBias;

/// Override to allow setting this property.
@property (nonatomic) float maxExposureTargetBias;

/// Override to allow setting this property.
@property (nonatomic) float exposureTargetOffset;

/// Value to return in \c isWhiteBalanceModeSupported:.
@property (nonatomic) BOOL whiteBalanceModeSupported;

/// Value to return in \c deviceWhiteBalanceGainsForTemperatureAndTintValues:.
@property (nonatomic) AVCaptureWhiteBalanceGains gainsToReturnFromConversion;

/// Value to return in \c isTorchModeSupported:.
@property (nonatomic) BOOL torchModeSupported;

/// Override to allow setting this property.
@property (nonatomic) BOOL hasFlash;

/// Override to allow setting this property.
@property (nonatomic) BOOL hasTorch;

/// Override to allow setting this property.
@property (nonatomic) float maxWhiteBalanceGain;

/// \c focusPointOfInterest at the time \c setFocusMode: was last called.
@property (readonly, nonatomic) CGPoint focusPointOfInterestDuringModeSet;

/// \c exposurePointOfInterest at the time \c setExposureMode: was last called.
@property (readonly, nonatomic) CGPoint exposurePointOfInterestDuringModeSet;

// From AVCaptureDevice.
@property (nonatomic) AVCaptureFocusMode focusMode;
@property (nonatomic) CGPoint focusPointOfInterest;
@property (readonly, atomic) float lensPosition;
@property (strong, nonatomic) AVCaptureDeviceFormat *activeFormat;
@property (nonatomic) AVCaptureExposureMode exposureMode;
@property (nonatomic) CGPoint exposurePointOfInterest;
@property (readonly, nonatomic) float exposureTargetBias;
@property (readonly, nonatomic) CMTime exposureDuration;
@property (readonly, nonatomic) float ISO;
@property (nonatomic) AVCaptureWhiteBalanceMode whiteBalanceMode;
@property (readonly, nonatomic) AVCaptureWhiteBalanceGains deviceWhiteBalanceGains;
@property (nonatomic) CGFloat videoZoomFactor;
@property (nonatomic) AVCaptureTorchMode torchMode;
@property (readonly, nonatomic) float torchLevel;
@property (readonly, nonatomic) AVCaptureDevicePosition position;
@property (readonly, nonatomic) NSArray *formats;
@property (nonatomic, getter=isSubjectAreaChangeMonitoringEnabled) BOOL
    subjectAreaChangeMonitoringEnabled;
- (void)setExposureModeCustomWithDuration:(CMTime)duration ISO:(float)ISO
                        completionHandler:(nullable void (^)(CMTime syncTime))handler;

// From AVCaptureDevice+Configure.
- (BOOL)cam_performWhileLocked:(BOOL (^)(NSError **errorPtr))action error:(NSError **)errorPtr;

@end

NS_ASSUME_NONNULL_END
