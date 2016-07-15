// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "CAMDeviceStub.h"

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMDeviceStub

- (instancetype)initWithPreset:(CAMDevicePreset * __unused)preset {
  self = [super init];
  return self;
}

#pragma mark -
#pragma mark CAMExposureDevice
#pragma mark -

- (RACSignal *)setSingleExposurePoint:(CGPoint __unused)exposurePoint {
  return self.setSingleExposurePointSignal;
}

- (RACSignal *)setContinuousExposurePoint:(CGPoint __unused)exposurePoint {
  return self.setContinuousExposurePointSignal;
}

- (RACSignal *)setLockedExposure {
  return self.setLockedExposureSignal;
}

- (RACSignal *)setExposureCompensation:(float __unused)value {
  return self.setExposureCompensationSignal;
}

#pragma mark -
#pragma mark CAMFlashDevice
#pragma mark -

- (RACSignal *)setFlashMode:(AVCaptureFlashMode __unused)flashMode {
  return self.setFlashModeSignal;
}

#pragma mark -
#pragma mark CAMFlipDevice
#pragma mark -

- (RACSignal *)setCamera:(CAMDeviceCamera * __unused)camera {
  return self.setCameraSignal;
}

#pragma mark -
#pragma mark CAMFocusDevice
#pragma mark -

- (RACSignal *)setSingleFocusPoint:(CGPoint __unused)focusPoint {
  return self.setSingleFocusPointSignal;
}

- (RACSignal *)setContinuousFocusPoint:(CGPoint __unused)focusPoint {
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
  return devicePoint;
}

- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint {
  return previewLayerPoint;
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

- (RACSignal *)setZoom:(CGFloat __unused)zoomFactor {
  return self.setZoomSignal;
}

- (RACSignal *)setZoom:(CGFloat __unused)zoomFactor rate:(float __unused)rate {
  return self.setZoomSignal;
}

@end

NS_ASSUME_NONNULL_END
