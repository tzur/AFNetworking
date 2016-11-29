// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Fake \c AVCaptureDevice for testing purposes, with many capabilities for mocking and recording
/// behaviors. It records whether \c lockForConfiguration: and \c unlockForConfiguration were
/// called, and in what order they were called, and can be configured to err in
/// \c lockForConfiguration:. Additionally, most \c is*Supported methods can be configured to
/// return a given value.
@interface CAMFakeAVCaptureDevice : AVCaptureDevice

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

/// Threads on which various \c set* methods were called.
@property (readonly, nonatomic) NSSet<NSThread *> *activeThreads;

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

/// Value to return in \c isFlashModeSupported:.
@property (nonatomic) BOOL flashModeSupported;

/// Value to return in \c isTorchModeSupported:.
@property (nonatomic) BOOL torchModeSupported;

/// Override to allow setting this property.
@property (nonatomic) BOOL hasFlash;

/// Override to allow setting this property.
@property (nonatomic) BOOL hasTorch;

/// Override to allow setting this property.
@property (nonatomic) BOOL flashActive;

/// \c focusPointOfInterest at the time \c setFocusMode: was last called.
@property (readonly, nonatomic) CGPoint focusPointOfInterestDuringModeSet;

/// \c exposurePointOfInterest at the time \c setExposureMode: was last called.
@property (readonly, nonatomic) CGPoint exposurePointOfInterestDuringModeSet;

@end

NS_ASSUME_NONNULL_END
