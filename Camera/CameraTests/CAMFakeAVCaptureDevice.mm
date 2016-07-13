// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMFakeAVCaptureDevice ()
// The properties below are overridden as readwrite so they can be set from this class.
@property (readwrite, nonatomic) AVCaptureFocusMode focusMode;
@property (readwrite, nonatomic) CGPoint focusPointOfInterest;
@property (readwrite, nonatomic) float lensPosition;
@property (readwrite, nonatomic) BOOL adjustingFocus;
@property (readwrite, nonatomic) AVCaptureExposureMode exposureMode;
@property (readwrite, nonatomic) CGPoint exposurePointOfInterest;
@property (readwrite, nonatomic) float exposureTargetBias;
@property (readwrite, nonatomic) BOOL adjustingExposure;
@property (readwrite, nonatomic) AVCaptureWhiteBalanceMode whiteBalanceMode;
@property (readwrite, nonatomic) AVCaptureWhiteBalanceGains deviceWhiteBalanceGains;
@property (readwrite, nonatomic) BOOL adjustingWhiteBalance;
@property (readwrite, nonatomic) CGFloat videoZoomFactor;
@property (readwrite, nonatomic) BOOL rampingVideoZoom;
@property (readwrite, nonatomic) AVCaptureFlashMode flashMode;
@end

@implementation CAMFakeAVCaptureDevice

@synthesize activeFormat = _activeFormat;

- (AVCaptureDeviceFormat *)activeFormat {
  return _activeFormat;
}

- (void)setActiveFormat:(AVCaptureDeviceFormat *)activeFormat {
  _activeFormat = activeFormat;
}

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [self.mediaTypes containsObject:mediaType];
}

#pragma mark -
#pragma mark Lock / Unlock
#pragma mark -

- (BOOL)lockForConfiguration:(NSError *__autoreleasing *)errorPtr {
  _didLock = YES;

  if (self.lockError) {
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
  RAC(self, lensPosition) = [@[@0.5, @0.6].rac_sequence.signal delay:0.005];
  RAC(self, adjustingFocus) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setFocusModeLockedWithLensPosition:(float)lensPosition
                         completionHandler:(void (^)(CMTime syncTime))handler {
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
  RAC(self, adjustingExposure) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setExposureTargetBias:(float)bias completionHandler:(void (^)(CMTime syncTime))handler {
  self.exposureTargetBias = bias;
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
                                           completionHandler:(void (^)(CMTime syncTime))handler {
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
#pragma mark Flash
#pragma mark -

- (BOOL)isFlashModeSupported:(AVCaptureFlashMode __unused)flashMode {
  return self.flashModeSupported;
}

@end

NS_ASSUME_NONNULL_END
