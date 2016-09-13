// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMBlankDevice.h"

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMBlankDevice

@synthesize exposureOffset = _exposureOffset;
@synthesize minExposureCompensation = _minExposureCompensation;
@synthesize maxExposureCompensation = _maxExposureCompensation;
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
  return [[RACSignal never] takeUntil:[self rac_willDeallocSignal]];
}

- (RACSignal *)videoFrames {
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
  LTParameterAssert(lensPosition <= 1, @"lensPosition above maximum");
  LTParameterAssert(lensPosition >= 0, @"lensPosition below minimum");
  return [RACSignal return:@(lensPosition)];
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
  LTParameterAssert(value <= self.maxExposureCompensation,
      @"Exposure compensation value above maximum");
  LTParameterAssert(value >= self.minExposureCompensation,
      @"Exposure compensation value below minimum");
  return [RACSignal return:@(value)];
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
  LTParameterAssert(zoomFactor <= self.maxZoomFactor, @"Zoom factor above maximum");
  LTParameterAssert(zoomFactor >= self.minZoomFactor, @"Zoom factor below minimum");
  return [RACSignal return:@(zoomFactor)];
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float __unused)rate {
  LTParameterAssert(zoomFactor <= self.maxZoomFactor, @"Zoom factor above maximum");
  LTParameterAssert(zoomFactor >= self.minZoomFactor, @"Zoom factor below minimum");
  return [RACSignal return:@(zoomFactor)];
}

- (RACSignal *)setFlashMode:(AVCaptureFlashMode __unused)flashMode {
  return [RACSignal error:[NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported]];
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
