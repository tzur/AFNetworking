// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMBlankDevice.h"

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMBlankDevice

@synthesize exposureOffset = _exposureOffset;
@synthesize minExposureCompensation = _minExposureCompensation;
@synthesize maxExposureCompensation = _maxExposureCompensation;
@synthesize exposureDuration = _exposureDuration;
@synthesize minExposureDuration = _minExposureDuration;
@synthesize maxExposureDuration = _maxExposureDuration;
@synthesize ISO = _ISO;
@synthesize minISO = _minISO;
@synthesize maxISO = _maxISO;
@synthesize hasFlash = _hasFlash;
@synthesize flashWillFire = _flashWillFire;
@synthesize currentFlashMode = _currentFlashMode;
@synthesize activeCamera = _activeCamera;
@synthesize canChangeCamera = _canChangeCamera;
@synthesize previewLayer = _previewLayer;
@synthesize interfaceOrientation = _interfaceOrientation;
@synthesize gravityOrientation = _gravityOrientation;
@synthesize hasZoom = _hasZoom;
@synthesize minZoomFactor = _minZoomFactor;
@synthesize maxZoomFactor = _maxZoomFactor;
@synthesize zoomFactor = _zoomFactor;
@synthesize hasTorch = _hasTorch;

- (instancetype)init {
  if (self = [super init]) {
    _activeCamera = $(CAMDeviceCameraBack);
    _previewLayer = [CALayer layer];
  }
  return self;
}

- (RACSignal *)setPixelFormat:(CAMPixelFormat *)pixelFormat {
  return [RACSignal return:pixelFormat];
}

- (RACSignal *)stillFramesWithTrigger:(RACSignal __unused *)trigger {
  return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput]];
}

- (RACSignal *)videoFrames {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal *)videoFramesErrors {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal *)subjectAreaChanged {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal *)audioFrames {
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (CGPoint)previewLayerPointFromDevicePoint:(CGPoint)devicePoint {
  return devicePoint;
}

- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint {
  return previewLayerPoint;
}

- (RACSignal *)setSingleFocusPoint:(CGPoint)focusPoint {
  return [RACSignal return:$(focusPoint)];
}

- (RACSignal *)setContinuousFocusPoint:(CGPoint)focusPoint {
  return [RACSignal return:$(focusPoint)];
}

- (RACSignal *)setLockedFocus {
  return [RACSignal return:$(CGPointNull)];
}

- (RACSignal *)setLockedFocusPosition:(CGFloat)lensPosition {
  if (lensPosition < 0 || lensPosition > 1 || !std::isfinite(lensPosition)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported]];
  } else {
    return [RACSignal return:@(lensPosition)];
  }
}

- (RACSignal *)setSingleExposurePoint:(CGPoint)exposurePoint {
  return [RACSignal return:$(exposurePoint)];
}

- (RACSignal *)setContinuousExposurePoint:(CGPoint)exposurePoint {
  return [RACSignal return:$(exposurePoint)];
}

- (RACSignal *)setLockedExposure {
  return [RACSignal return:$(CGPointNull)];
}

- (RACSignal *)setExposureCompensation:(float)value {
  if (value < self.minExposureCompensation || value > self.maxExposureCompensation ||
      !std::isfinite(value)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:@(value)];
  }
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration {
  if (exposureDuration < self.minExposureDuration || exposureDuration > self.maxExposureDuration ||
      !std::isfinite(exposureDuration)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:@(exposureDuration)];
  }
}

- (RACSignal *)setManualExposureWithISO:(float)ISO {
  if (ISO < self.minISO || ISO > self.maxISO || !std::isfinite(ISO)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:@(ISO)];
  }
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration andISO:(float)ISO {
  if (exposureDuration < self.minExposureDuration || exposureDuration > self.maxExposureDuration ||
      !std::isfinite(exposureDuration) || ISO < self.minISO || ISO > self.maxISO ||
      !std::isfinite(ISO)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:RACTuplePack(@(exposureDuration), @(ISO))];
  }
}

- (RACSignal *)setSingleWhiteBalance {
  return [RACSignal return:[RACUnit defaultUnit]];
}

- (RACSignal *)setContinuousWhiteBalance {
  return [RACSignal return:[RACUnit defaultUnit]];
}

- (RACSignal *)setLockedWhiteBalance {
  return [RACSignal return:[RACUnit defaultUnit]];
}

- (RACSignal *)setLockedWhiteBalanceWithTemperature:(float)temperature tint:(float)tint {
  return [RACSignal return:RACTuplePack(@(temperature), @(tint))];
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor {
  if (zoomFactor < self.minZoomFactor || zoomFactor > self.maxZoomFactor ||
      !std::isfinite(zoomFactor)) {
     return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:@(zoomFactor)];
  }
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float __unused)rate {
  if (zoomFactor < self.minZoomFactor || zoomFactor > self.maxZoomFactor ||
      !std::isfinite(zoomFactor)) {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported]];
  } else {
    return [RACSignal return:@(zoomFactor)];
  }
}

- (RACSignal *)setFlashMode:(AVCaptureFlashMode __unused)flashMode {
  return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported]];
}

- (RACSignal *)setTorchLevel:(float __unused)torchLevel {
  return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported]];
}

- (nonnull RACSignal *)setTorchMode:(AVCaptureTorchMode __unused)torchMode {
  return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported]];
}

- (RACSignal *)setCamera:(CAMDeviceCamera *)camera {
  if ([camera isEqual:$(CAMDeviceCameraBack)]) {
    return [RACSignal return:camera];
  } else {
    return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeCameraUnavailable]];
  }
}

@end

NS_ASSUME_NONNULL_END
