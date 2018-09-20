// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMFakeAVCaptureDevice ()
// The properties below are overridden as readwrite so they can be set from this class.
@property (readwrite, atomic) float lensPosition;
@property (readwrite, nonatomic) float torchLevel;
@property (readwrite, atomic) BOOL adjustingFocus;
@property (readwrite, nonatomic) float exposureTargetBias;
@property (readwrite, nonatomic) CMTime exposureDuration;
@property (readwrite, nonatomic) float ISO;
@property (readwrite, atomic) BOOL adjustingExposure;
@property (readwrite, nonatomic) AVCaptureWhiteBalanceGains deviceWhiteBalanceGains;
@property (readwrite, atomic) BOOL adjustingWhiteBalance;
@property (readwrite, atomic) BOOL rampingVideoZoom;
@property (readwrite, nonatomic) CGPoint focusPointOfInterestDuringModeSet;
@property (readwrite, nonatomic) CGPoint exposurePointOfInterestDuringModeSet;
@end

@implementation CAMFakeAVCaptureDevice

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [self.mediaTypes containsObject:mediaType];
}

#pragma mark -
#pragma mark Lock / Unlock
#pragma mark -

- (BOOL)cam_performWhileLocked:(BOOL (^)(NSError **errorPtr))action
                         error:(NSError *__autoreleasing *)errorPtr {
  LTParameterAssert(action, @"action block must be non-nil");
  BOOL success;

  success = [self lockForConfiguration:errorPtr];
  if (success) {
    success = action(errorPtr);
  }
  [self unlockForConfiguration];

  return success;
}

- (BOOL)lockForConfiguration:(NSError *__autoreleasing *)errorPtr {
  _didLock = YES;

  if (errorPtr && self.lockError) {
    *errorPtr = self.lockError;
    return NO;
  } else {
    return YES;
  }
}

- (void)unlockForConfiguration {
  if (self.didLock) {
    _didUnlockWhileLocked = YES;
  }

  _didUnlock = YES;
}

#pragma mark -
#pragma mark Focus
#pragma mark -

- (BOOL)isFocusModeSupported:(AVCaptureFocusMode __unused)mode {
  return self.focusModeSupported;
}

- (BOOL)isFocusPointOfInterestSupported {
  return self.focusPointOfInterestSupported;
}

- (void)setFocusMode:(AVCaptureFocusMode)focusMode {
  _focusMode = focusMode;
  self.focusPointOfInterestDuringModeSet = self.focusPointOfInterest;
  RAC(self, lensPosition) = [@[@0.5, @0.6].rac_sequence.signal delay:0.005];
  RAC(self, adjustingFocus) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setFocusModeLockedWithLensPosition:(float)lensPosition
                         completionHandler:(nullable void (^)(CMTime syncTime))handler {
  self.lensPosition = lensPosition;
  handler(kCMTimeZero);
}

#pragma mark -
#pragma mark Exposure
#pragma mark -

- (BOOL)isExposureModeSupported:(AVCaptureExposureMode __unused)exposureMode {
  return self.exposureModeSupported;
}

- (BOOL)isExposurePointOfInterestSupported {
  return self.exposurePointOfInterestSupported;
}

- (void)setExposureMode:(AVCaptureExposureMode)exposureMode {
  _exposureMode = exposureMode;
  self.exposurePointOfInterestDuringModeSet = self.exposurePointOfInterest;
  RAC(self, adjustingExposure) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setExposureTargetBias:(float)bias
            completionHandler:(nullable void (^)(CMTime syncTime))handler {
  self.exposureTargetBias = bias;
  handler(kCMTimeZero);
}

- (void)setExposureModeCustomWithDuration:(CMTime)duration ISO:(float)ISO
                        completionHandler:(nullable void (^)(CMTime syncTime))handler {
  _exposureMode = AVCaptureExposureModeCustom;

  if (CMTimeCompare(duration, AVCaptureExposureDurationCurrent) != 0) {
    self.exposureDuration = duration;
  }

  if (ISO != AVCaptureISOCurrent) {
    self.ISO = ISO;
  }

  handler(kCMTimeZero);
}

#pragma mark -
#pragma mark White Balance
#pragma mark -

- (BOOL)isWhiteBalanceModeSupported:(AVCaptureWhiteBalanceMode __unused)whiteBalanceMode {
  return self.whiteBalanceModeSupported;
}

- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode {
  _whiteBalanceMode = whiteBalanceMode;
  RAC(self, adjustingWhiteBalance) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (AVCaptureWhiteBalanceGains)deviceWhiteBalanceGainsForTemperatureAndTintValues:
    (AVCaptureWhiteBalanceTemperatureAndTintValues __unused)tempAndTintValues {
  return self.gainsToReturnFromConversion;
}

- (void)setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:
    (AVCaptureWhiteBalanceGains)whiteBalanceGains
    completionHandler:(nullable void (^)(CMTime syncTime))handler {
  self.deviceWhiteBalanceGains = whiteBalanceGains;
  handler(kCMTimeZero);
}

#pragma mark -
#pragma mark Zoom
#pragma mark -

- (void)rampToVideoZoomFactor:(CGFloat)factor withRate:(float __unused)rate {
  self.videoZoomFactor = factor;
  RAC(self, rampingVideoZoom) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

#pragma mark -
#pragma mark Torch
#pragma mark -

- (BOOL)isTorchModeSupported:(AVCaptureTorchMode __unused)torchMode {
  return self.torchModeSupported;
}

- (BOOL)setTorchModeOnWithLevel:(float)torchLevel
                          error:(NSError __unused *__autoreleasing *)outError {
  self.torchMode = AVCaptureTorchModeOn;
  self.torchLevel = torchLevel;
  return YES;
}

@end

NS_ASSUME_NONNULL_END
