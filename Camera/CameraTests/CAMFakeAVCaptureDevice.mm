// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMFakeAVCaptureDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMFakeAVCaptureDevice ()
@property (readonly, nonatomic) NSMutableSet<NSThread *> *mutableActiveThreads;
// The properties below are overridden as readwrite so they can be set from this class.
@property (readwrite, nonatomic) AVCaptureFocusMode focusMode;
@property (readwrite, nonatomic) CGPoint focusPointOfInterest;
@property (readwrite, nonatomic) float lensPosition;
@property (readwrite, nonatomic) float torchLevel;
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
@property (readwrite, nonatomic) AVCaptureTorchMode torchMode;
@property (readwrite, nonatomic) CGPoint focusPointOfInterestDuringModeSet;
@property (readwrite, nonatomic) CGPoint exposurePointOfInterestDuringModeSet;
@end

@implementation CAMFakeAVCaptureDevice

@synthesize activeFormat = _activeFormat;

- (instancetype)init {
  if (self = [super init]) {
    _mutableActiveThreads = [NSMutableSet set];
  }
  return self;
}

- (AVCaptureDeviceFormat *)activeFormat {
  return _activeFormat;
}

- (void)setActiveFormat:(AVCaptureDeviceFormat *)activeFormat {
  _activeFormat = activeFormat;
}

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [self.mediaTypes containsObject:mediaType];
}

- (NSSet *)activeThreads {
  @synchronized (self) {
    return [self.mutableActiveThreads copy];
  }
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
  self.focusPointOfInterestDuringModeSet = self.focusPointOfInterest;
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
  RAC(self, lensPosition) = [@[@0.5, @0.6].rac_sequence.signal delay:0.005];
  RAC(self, adjustingFocus) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setFocusModeLockedWithLensPosition:(float)lensPosition
                         completionHandler:(void (^)(CMTime syncTime))handler {
  self.lensPosition = lensPosition;
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
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
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
  RAC(self, adjustingExposure) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

- (void)setExposureTargetBias:(float)bias completionHandler:(void (^)(CMTime syncTime))handler {
  self.exposureTargetBias = bias;
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
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
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
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
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
  handler(kCMTimeZero);
}

#pragma mark -
#pragma mark Zoom
#pragma mark -

- (void)rampToVideoZoomFactor:(CGFloat)factor withRate:(float __unused)rate {
  self.videoZoomFactor = factor;
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
  RAC(self, rampingVideoZoom) = [@[@YES, @NO].rac_sequence.signal delay:0.005];
}

#pragma mark -
#pragma mark Flash
#pragma mark -

- (BOOL)isFlashModeSupported:(AVCaptureFlashMode __unused)flashMode {
  return self.flashModeSupported;
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
  @synchronized (self) {
    [self.mutableActiveThreads addObject:[NSThread currentThread]];
  }
  return YES;
}

@end

NS_ASSUME_NONNULL_END
