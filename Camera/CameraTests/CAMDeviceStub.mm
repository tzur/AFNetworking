// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceStub.h"

#import "CAMHardwareSession.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMDeviceStub

@synthesize interfaceOrientation = _interfaceOrientation;
@synthesize gravityOrientation = _gravityOrientation;
@synthesize minExposureDuration = _minExposureDuration;
@synthesize maxExposureDuration = _maxExposureDuration;
@synthesize minISO = _minISO;
@synthesize maxISO = _maxISO;

- (instancetype)initWithSession:(CAMHardwareSession __unused *)session {
  return self = [super init];
}

#pragma mark -
#pragma mark CAMExposureDevice
#pragma mark -

- (RACSignal *)setSingleExposurePoint:(CGPoint)exposurePoint {
  self.lastReceivedSingleExposurePoint = exposurePoint;
  return self.setSingleExposurePointSignal;
}

- (RACSignal *)setContinuousExposurePoint:(CGPoint)exposurePoint {
  self.lastReceivedContinuousExposurePoint = exposurePoint;
  return self.setContinuousExposurePointSignal;
}

- (RACSignal *)setLockedExposure {
  return self.setLockedExposureSignal;
}

- (RACSignal *)setExposureCompensation:(float __unused)value {
  return self.setExposureCompensationSignal;
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval __unused)exposureDuration {
  return self.setManualExposureWithDurationSignal;
}

- (RACSignal *)setManualExposureWithISO:(float __unused)ISO {
  return self.setManualExposureWithISOSignal;
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval __unused)exposureDuration
                                      andISO:(float __unused)ISO {
  return self.setManualExposureWithDurationAndISOSignal;
}

#pragma mark -
#pragma mark CAMFlashDevice
#pragma mark -

- (RACSignal *)setFlashMode:(AVCaptureFlashMode __unused)flashMode {
  return self.setFlashModeSignal;
}

#pragma mark -
#pragma mark CAMTorchDevice
#pragma mark -

- (RACSignal *)setTorchLevel:(float __unused)torchLevel {
  return self.setTorchLevelSignal;
}

- (RACSignal *)setTorchMode:(AVCaptureTorchMode)torchMode {
  self.lastReceivedTorchMode = torchMode;
  return self.setTorchModeSignal;
}

#pragma mark -
#pragma mark CAMFlipDevice
#pragma mark -

- (RACSignal *)setCamera:(CAMDeviceCamera * __unused)camera {
  self.setCameraWasCalled = YES;
  return self.setCameraSignal;
}

#pragma mark -
#pragma mark CAMFocusDevice
#pragma mark -

- (RACSignal *)setSingleFocusPoint:(CGPoint)focusPoint {
  self.lastReceivedSingleFocusPoint = focusPoint;
  return self.setSingleFocusPointSignal;
}

- (RACSignal *)setContinuousFocusPoint:(CGPoint)focusPoint {
  self.lastReceivedContinuousFocusPoint = focusPoint;
  return self.setContinuousFocusPointSignal;
}

- (RACSignal *)setLockedFocus {
  return self.setLockedFocusSignal;
}

- (RACSignal *)setLockedFocusPosition:(CGFloat __unused)lensPosition {
  return self.setLockedFocusPositionSignal;
}

#pragma mark -
#pragma mark CAMPreviewLayerDevice
#pragma mark -

- (CGPoint)previewLayerPointFromDevicePoint:(CGPoint)devicePoint {
  return (devicePoint * 2);
}

- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint {
  return (previewLayerPoint * 0.5);
}

#pragma mark -
#pragma mark CAMVideoDevice
#pragma mark -

- (RACSignal *)setPixelFormat:(CAMPixelFormat * __unused)pixelFormat {
  return self.setPixelFormatSignal;
}

- (RACSignal *)stillFramesWithTrigger:(RACSignal * __unused)trigger {
  return self.stillFramesWithTriggerSignal;
}

#pragma mark -
#pragma mark CAMWhiteBalanceDevice
#pragma mark -

- (RACSignal *)setSingleWhiteBalance {
  return self.setSingleWhiteBalanceSignal;
}

- (RACSignal *)setContinuousWhiteBalance {
  return self.setContinuousWhiteBalanceSignal;
}

- (RACSignal *)setLockedWhiteBalance {
  return self.setLockedWhiteBalanceSignal;
}

- (RACSignal *)setLockedWhiteBalanceWithTemperature:(float __unused)temperature
                                               tint:(float __unused)tint {
  return self.setLockedWhiteBalanceSignal;
}

#pragma mark -
#pragma mark CAMZoomDevice
#pragma mark -

- (RACSignal *)setZoom:(CGFloat)zoomFactor {
  self.lastReceivedZoom = zoomFactor;
  return self.setZoomSignal;
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float __unused)rate {
  self.lastReceivedZoom = zoomFactor;
  return self.setZoomSignal;
}

@end

NS_ASSUME_NONNULL_END
