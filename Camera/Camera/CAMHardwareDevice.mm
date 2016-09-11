// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareDevice.h"

#import <LTEngine/LTMMTexture.h>
#import <LTEngine/LTGLContext.h>

#import "AVCaptureDevice+Configure.h"
#import "CAMDevicePreset.h"
#import "CAMHardwareSession.h"
#import "CAMVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMHardwareDevice () <AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate>

/// Underlying session that holds all AV inputs and outputs.
@property (readonly, nonatomic) CAMHardwareSession *session;

/// Subject for sending video frames.
@property (readonly, nonatomic) RACSubject *videoFramesSignalsSubject;

/// Subject for sending audio frames.
@property (readonly, nonatomic) RACSubject *audioFramesSubject;

// The properties below copied from the protocols and synthesized as readwrite so that KVO will
// work.

/// Difference between the current scene's exposure metering and the current exposure settings, in
/// EV units.
@property (nonatomic) float exposureOffset;

/// Minimum exposure compensation value supported by the camera.
@property (nonatomic) CGFloat minExposureCompensation;

/// Maximum exposure compensation value supported by the camera.
@property (nonatomic) CGFloat maxExposureCompensation;

/// Whether the camera is capable of zooming.
@property (nonatomic) BOOL hasZoom;

/// Minimum zoom factor supported by the camera.
@property (nonatomic) CGFloat minZoomFactor;

/// Maximum zoom factor supported by the camera.
@property (nonatomic) CGFloat maxZoomFactor;

/// Current zoom factor of the camera.
@property (nonatomic) CGFloat zoomFactor;

/// Whether the camera is capable of flashing.
@property (nonatomic) BOOL hasFlash;

/// Whether the camera has a torch.
@property (nonatomic) BOOL hasTorch;

/// Whether the camera's flash will light if an image is captured right now. When the current flash
/// mode is \c AVCaptureFlashModeAuto, this depends on current exposure measurements.
@property (nonatomic) BOOL flashWillFire;

/// Currently active flash mode.
@property (nonatomic) AVCaptureFlashMode currentFlashMode;

/// Currently active physical camera device.
@property (nonatomic) CAMDeviceCamera *activeCamera;

/// Whether or not there are more physical camera devices available.
@property (nonatomic) BOOL canChangeCamera;

@end

@implementation CAMHardwareDevice

@synthesize previewLayerWithPortraitOrientation = _previewLayerWithPortraitOrientation;
@synthesize videoFramesWithPortraitOrientation = _videoFramesWithPortraitOrientation;
@synthesize deviceOrientation = _deviceOrientation;

- (instancetype)initWithSession:(CAMHardwareSession *)session {
  if (self = [super init]) {
    _session = session;
    _videoFramesSignalsSubject = [RACSubject subject];
    _audioFramesSubject = [RACSubject subject];
    self.session.videoDelegate = self;
    self.session.audioDelegate = self;
    [self setupProperties];
  }
  return self;
}

- (void)setupProperties {
  [self setupExposureProperties];
  [self setupZoomProperties];
  [self setupFlashProperties];
  [self setupTorchProperties];
  [self setupFlipProperties];
}

- (void)setupExposureProperties {
  RAC(self, exposureOffset, @0) = RACObserve(self, session.videoDevice.exposureTargetOffset);

  RAC(self, minExposureCompensation, @0) =
      RACObserve(self, session.videoDevice.minExposureTargetBias);

  RAC(self, maxExposureCompensation, @0) =
      RACObserve(self, session.videoDevice.maxExposureTargetBias);
}

- (void)setupZoomProperties {
  RAC(self, hasZoom, @NO) = [RACSignal
      combineLatest:@[
          RACObserve(self, minZoomFactor),
          RACObserve(self, maxZoomFactor)
      ] reduce:(id)^NSNumber *(NSNumber *minZoomFactor, NSNumber *maxZoomFactor) {
        return @([maxZoomFactor CGFloatValue] / [minZoomFactor CGFloatValue] > 1.1);
      }];

  self.minZoomFactor = 1;

  RAC(self, maxZoomFactor, @1) =
      RACObserve(self, session.videoDevice.activeFormat.videoMaxZoomFactor);

  RAC(self, zoomFactor, @1) = RACObserve(self, session.videoDevice.videoZoomFactor);
}

- (void)setupFlashProperties {
  RAC(self, hasFlash, @NO) = RACObserve(self, session.videoDevice.hasFlash);

  RAC(self, flashWillFire, @NO) = RACObserve(self, session.videoDevice.flashActive);

  RAC(self, currentFlashMode, @(AVCaptureFlashModeOff)) =
      RACObserve(self, session.videoDevice.flashMode);
}

- (void)setupTorchProperties {
  RAC(self, hasTorch, @NO) = RACObserve(self, session.videoDevice.hasTorch);
}

- (void)setupFlipProperties {
  RAC(self, activeCamera) = [[RACObserve(self, session.videoDevice.position)
      ignore:nil]
      map:^CAMDeviceCamera *(NSNumber *position) {
        switch ((AVCaptureDevicePosition)position.integerValue) {
          case AVCaptureDevicePositionBack:
            return $(CAMDeviceCameraBack);
          case AVCaptureDevicePositionFront:
            return $(CAMDeviceCameraFront);
          case AVCaptureDevicePositionUnspecified:
            return nil;
        }
      }];

  self.canChangeCamera = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1;
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutput / AVCaptureAudioDataOutput
#pragma mark -

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection __unused *)connection {
  if ([captureOutput isKindOfClass:[AVCaptureVideoDataOutput class]]) {
    [self didOutputVideoSampleBuffer:sampleBuffer];
  } else if ([captureOutput isKindOfClass:[AVCaptureAudioDataOutput class]]) {
    [self didOutputAudioSampleBuffer:sampleBuffer];
  } else {
    LogError(@"Sample buffer received from unknown output.");
  }
}

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // Conversion of CMSampleBuffers to LTTextures should be done synchronously from here, because
  // sampleBuffer may be reused immediately at the end of the delegate method. Async is possible
  // but requires CFRetain and CFRelease.

  RACSignal *convertFrame = [RACSignal defer:^RACSignal *{
    if (![LTGLContext currentContext]) {
      // This sometimes happens for the first few frames, because the sampleBuffer delegate & queue
      // are set after AVCaptureSession's initialization.
      LogError(@"No LTGLContext in didOutputVideoSampleBuffer:");
      return [RACSignal empty];
    }

    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    LTAssert(pixelBuffer != NULL, @"Video sampleBuffer does not contain pixelBuffer");

    CMSampleTimingInfo timingInfo;
    OSStatus status = CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timingInfo);
    LTAssert(status == noErr, @"Failed to retrieve sample timing, status: %d", (int)status);

    id<CAMVideoFrame> frame;
    if (CVPixelBufferIsPlanar(pixelBuffer)) {
      LTTexture *yTexture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer planeIndex:0];
      LTTexture *cbcrTexture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer planeIndex:1];
      frame = [[CAMVideoFrameYCbCr alloc] initWithYTexture:yTexture cbcrTexture:cbcrTexture
                                          sampleTimingInfo:timingInfo];
    } else {
      LTTexture *bgraTexture = [[LTMMTexture alloc] initWithPixelBuffer:pixelBuffer];
      frame = [[CAMVideoFrameBGRA alloc] initWithBGRATexture:bgraTexture
                                            sampleTimingInfo:timingInfo];
    }

    return [RACSignal return:frame];
  }];

  [self.videoFramesSignalsSubject sendNext:convertFrame];
}

- (void)didOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  [self.audioFramesSubject sendNext:[NSValue value:&sampleBuffer
                                      withObjCType:@encode(CMSampleBufferRef)]];
}

#pragma mark -
#pragma mark CAMVideoDevice
#pragma mark -

- (RACSignal *)setPixelFormat:(CAMPixelFormat *)pixelFormat {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    self.session.videoOutput.videoSettings = pixelFormat.videoSettings;
    return [RACSignal return:pixelFormat];
  }];
}

- (RACSignal *)stillFramesWithTrigger:(RACSignal *)trigger {
  @weakify(self);
  RACSignal *captureStillImage = [RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        [self.session.stillOutput
         captureStillImageAsynchronouslyFromConnection:self.session.stillConnection
         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
           if (error) {
             [subscriber sendError:[NSError
                                    lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput
                                    underlyingError:error]];
           } else {
             NSData *data = [AVCaptureStillImageOutput
                             jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             UIImage *image = [UIImage imageWithData:data];
             [subscriber sendNext:image];
             [subscriber sendCompleted];
           }
         }];
        return nil;
      }];

  return [trigger flattenMap:^RACStream *(id) {
    return captureStillImage;
  }];
}

- (RACSignal *)videoFrames {
  return [self.videoFramesSignalsSubject switchToLatest];
}

- (void)setVideoFramesWithPortraitOrientation:(BOOL)videoFramesWithPortraitOrientation {
  _videoFramesWithPortraitOrientation = videoFramesWithPortraitOrientation;
  if (self.videoFramesWithPortraitOrientation) {
    self.session.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
  } else {
    self.session.videoConnection.videoOrientation =
        (AVCaptureVideoOrientation)self.deviceOrientation;
  }
}

- (void)setDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
  _deviceOrientation = deviceOrientation;
  self.session.stillConnection.videoOrientation = (AVCaptureVideoOrientation)self.deviceOrientation;
  if (!self.videoFramesWithPortraitOrientation) {
    self.session.videoConnection.videoOrientation =
        (AVCaptureVideoOrientation)self.deviceOrientation;
  }
  if (!self.previewLayerWithPortraitOrientation) {
    self.session.previewLayer.connection.videoOrientation =
        (AVCaptureVideoOrientation)self.deviceOrientation;
  }
}

- (RACSignal *)subjectAreaChanged {
  return [[[[NSNotificationCenter defaultCenter]
      rac_addObserverForName:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil]
      takeUntil:[self rac_willDeallocSignal]]
      mapReplace:[RACUnit defaultUnit]];
}

#pragma mark -
#pragma mark CAMAudioDevice
#pragma mark -

- (RACSignal *)audioFrames {
  return self.audioFramesSubject;
}

#pragma mark -
#pragma mark CAMPreviewLayerDevice
#pragma mark -

- (CGPoint)previewLayerPointFromDevicePoint:(CGPoint)devicePoint {
  return [self.session.previewLayer pointForCaptureDevicePointOfInterest:devicePoint];
}

- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint {
  return [self.session.previewLayer captureDevicePointOfInterestForPoint:previewLayerPoint];
}

- (CALayer *)previewLayer {
  return self.session.previewLayer;
}

- (void)setPreviewLayerWithPortraitOrientation:(BOOL)previewLayerWithPortraitOrientation {
  _previewLayerWithPortraitOrientation = previewLayerWithPortraitOrientation;
  if (self.previewLayerWithPortraitOrientation) {
    self.session.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
  } else {
    self.session.previewLayer.connection.videoOrientation =
        (AVCaptureVideoOrientation)self.deviceOrientation;
  }
}

#pragma mark -
#pragma mark CAMFocusDevice
#pragma mark -

- (RACSignal *)setSingleFocusPoint:(CGPoint)focusPoint {
  return [[[self setFocusMode:AVCaptureFocusModeAutoFocus point:focusPoint]
      concat:[self adjustingFocus:self.session.videoDevice]]
      mapReplace:$(focusPoint)];
}

- (RACSignal *)setContinuousFocusPoint:(CGPoint)focusPoint {
  return [[[self setFocusMode:AVCaptureFocusModeContinuousAutoFocus point:focusPoint]
      concat:[self adjustingFocus:self.session.videoDevice]]
      mapReplace:$(focusPoint)];
}

- (RACSignal *)adjustingFocus:(AVCaptureDevice *)device {
  // adjustingFocus seems to change between YES and NO several times before lensPosition starts
  // changing. Only after lensPosition has started changing, adjustingFocus becomes credible.
  return [[[[[[RACObserve(device, lensPosition)
      skip:1]
      take:1]
      ignoreValues]
      concat:RACObserve(device, adjustingFocus)]
      ignore:@YES]
      take:1];
}

- (RACSignal *)setLockedFocus {
  return [[self setFocusMode:AVCaptureFocusModeLocked point:CGPointZero]
      concat:[RACSignal return:$(CGPointNull)]];
}

- (RACSignal *)setFocusMode:(AVCaptureFocusMode)mode point:(CGPoint)point {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setFocusMode:mode point:point error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }];
}

- (BOOL)setFocusMode:(AVCaptureFocusMode)mode point:(CGPoint)point
               error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isFocusModeSupported:mode] &&
        (mode == AVCaptureFocusModeLocked || device.isFocusPointOfInterestSupported)) {
      device.focusMode = mode;

      if (mode != AVCaptureFocusModeLocked) {
        device.focusPointOfInterest = point;
      }

      return YES;
    } else {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
      return NO;
    }
  } error:error];
}

- (RACSignal *)setLockedFocusPosition:(CGFloat)lensPosition {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        [device setFocusModeLockedWithLensPosition:lensPosition
                                 completionHandler:^(CMTime __unused syncTime) {
                                   [subscriber sendNext:@(lensPosition)];
                                   [subscriber sendCompleted];
                                 }];
        return YES;
      } else {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        return NO;
      }
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }];
}

#pragma mark -
#pragma mark CAMExposureDevice
#pragma mark -

- (RACSignal *)setSingleExposurePoint:(CGPoint)exposurePoint {
  return [[[self setExposureMode:AVCaptureExposureModeAutoExpose point:exposurePoint]
      concat:[self adjustingExposure:self.session.videoDevice]]
      mapReplace:$(exposurePoint)];
}

- (RACSignal *)setContinuousExposurePoint:(CGPoint)exposurePoint {
  return [[[self setExposureMode:AVCaptureExposureModeContinuousAutoExposure point:exposurePoint]
      concat:[self adjustingExposure:self.session.videoDevice]]
      mapReplace:$(exposurePoint)];
}

- (RACSignal *)adjustingExposure:(AVCaptureDevice *)device {
  return [[[RACObserve(device, adjustingExposure)
      skip:1]
      ignore:@YES]
      take:1];
}

- (RACSignal *)setLockedExposure {
  return [[self setExposureMode:AVCaptureExposureModeLocked point:CGPointNull]
      concat:[RACSignal return:$(CGPointNull)]];
}

- (RACSignal *)setExposureMode:(AVCaptureExposureMode)mode point:(CGPoint)point {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setExposureMode:mode point:point error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }];
}

- (BOOL)setExposureMode:(AVCaptureExposureMode)mode point:(CGPoint)point
                  error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isExposureModeSupported:mode] &&
        (CGPointIsNull(point) || device.isExposurePointOfInterestSupported)) {
      device.exposureMode = mode;
      if (!CGPointIsNull(point)) {
        device.exposurePointOfInterest = point;
      }
      return YES;
    } else {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported];
      return NO;
    }
  } error:error];
}

- (RACSignal *)setExposureCompensation:(float)value {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    LTParameterAssert(value <= device.maxExposureTargetBias,
        @"Exposure compensation value above maximum");
    LTParameterAssert(value >= device.minExposureTargetBias,
        @"Exposure compensation value below minimum");
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **) {
      [device setExposureTargetBias:value completionHandler:^(CMTime __unused syncTime) {
        [subscriber sendNext:@(value)];
        [subscriber sendCompleted];
      }];
      return YES;
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }];
}

#pragma mark -
#pragma mark CAMWhiteBalanceDevice
#pragma mark -

- (RACSignal *)setSingleWhiteBalance {
  return [[[self setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance]
      concat:[self adjustingWhiteBalance:self.session.videoDevice]]
      mapReplace:[RACUnit defaultUnit]];
}

- (RACSignal *)setContinuousWhiteBalance {
  return [[[self setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]
      concat:[self adjustingWhiteBalance:self.session.videoDevice]]
      mapReplace:[RACUnit defaultUnit]];
}

- (RACSignal *)adjustingWhiteBalance:(AVCaptureDevice *)device {
  return [[[RACObserve(device, adjustingWhiteBalance)
      skip:1]
      ignore:@YES]
      take:1];
}

- (RACSignal *)setLockedWhiteBalance {
  return [[self setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked]
      concat:[RACSignal return:[RACUnit defaultUnit]]];
}

- (RACSignal *)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setWhiteBalanceMode:mode error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }];
}

- (BOOL)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode
                      error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isWhiteBalanceModeSupported:mode]) {
      device.whiteBalanceMode = mode;
      return YES;
    } else {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
      return NO;
    }
  } error:error];
}

- (RACSignal *)setLockedWhiteBalanceWithTemperature:(float)temperature tint:(float)tint {
  @weakify(self);
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        AVCaptureWhiteBalanceGains gains =
            [device deviceWhiteBalanceGainsForTemperatureAndTintValues:{temperature, tint}];
        [device
         setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains
         completionHandler:^(CMTime) {
           [subscriber sendNext:RACTuplePack(@(temperature), @(tint))];
           [subscriber sendCompleted];
         }];
        return YES;
      } else {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        return NO;
      }
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }];
}

#pragma mark -
#pragma mark CAMZoomDevice
#pragma mark -

- (RACSignal *)setZoom:(CGFloat)zoomFactor {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    LTParameterAssert(zoomFactor <= self.maxZoomFactor, @"Zoom factor above maximum");
    LTParameterAssert(zoomFactor >= self.minZoomFactor, @"Zoom factor below minimum");
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **) {
      device.videoZoomFactor = zoomFactor;
      return YES;
    } error:&error];
    return success ? [RACSignal return:@(zoomFactor)] : [RACSignal error:error];
  }];
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float)rate {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    LTParameterAssert(zoomFactor <= self.maxZoomFactor, @"Zoom factor above maximum");
    LTParameterAssert(zoomFactor >= self.minZoomFactor, @"Zoom factor below minimum");
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **) {
      [device rampToVideoZoomFactor:zoomFactor withRate:rate];
      return YES;
    } error:&error];
    return success ? [[self rampingZoom:device] mapReplace:@(zoomFactor)] : [RACSignal error:error];
  }];
}

- (RACSignal *)rampingZoom:(AVCaptureDevice *)device {
  return [[[RACObserve(device, rampingVideoZoom)
      skip:1]
      ignore:@YES]
      take:1];
}

#pragma mark -
#pragma mark CAMFlashDevice
#pragma mark -

- (RACSignal *)setFlashMode:(AVCaptureFlashMode)flashMode {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    AVCaptureDevice *device = self.session.videoDevice;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if ([device isFlashModeSupported:flashMode]) {
        device.flashMode = flashMode;
        return YES;
      } else {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported];
        return NO;
      }
    } error:&error];
    return success ? [RACSignal return:@(flashMode)] : [RACSignal error:error];
  }];
}

#pragma mark -
#pragma mark CAMTorchDevice
#pragma mark -

- (RACSignal *)setTorchLevel:(float)torchLevel {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setTorchLevel:torchLevel error:&error];
    return success ? [RACSignal return:@(torchLevel)] : [RACSignal error:error];
  }];
}

- (BOOL)setTorchLevel:(float)torchLevel error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    LTParameterAssert(torchLevel <= 1, @"Torch level factor above maximum");
    LTParameterAssert(torchLevel >= 0, @"Torch level below minimum");
    if (torchLevel == 0) {
      return [self setDeviceTorchOff:device error:errorPtr];
    } else {
      return [self setDeviceTorchOn:device withLevel:torchLevel error:errorPtr];
    }
  } error:error];
  return success;
}

- (BOOL)setDeviceTorchOff:(AVCaptureDevice *)device error:(NSError *__autoreleasing *)errorPtr {
  if (![device isTorchModeSupported:AVCaptureTorchModeOff]) {
    *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
    return NO;
  }
  device.torchMode = AVCaptureTorchModeOff;
  return YES;
}

- (BOOL)setDeviceTorchOn:(AVCaptureDevice *)device withLevel:(float)torchLevel
                   error:(NSError *__autoreleasing *)errorPtr {
  if (![device isTorchModeSupported:AVCaptureTorchModeOn]) {
    *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
    return NO;
  }
  NSError *setLevelError;
  BOOL torchWasSet = [device setTorchModeOnWithLevel:torchLevel error:&setLevelError];
  if (setLevelError || !torchWasSet) {
    *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported
                          underlyingError:setLevelError];
    return NO;
  }
  return YES;
}

#pragma mark -
#pragma mark CAMFlipDevice
#pragma mark -

- (RACSignal *)setCamera:(CAMDeviceCamera *)camera {
  @weakify(self);
  return [RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self.session setCamera:camera error:&error];
    return success ? [RACSignal return:camera] : [RACSignal error:error];
  }];
}

@end

NS_ASSUME_NONNULL_END
