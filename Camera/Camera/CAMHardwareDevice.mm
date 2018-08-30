// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareDevice.h"

#import "AVCaptureDevice+Configure.h"
#import "CAMAudioFrame.h"
#import "CAMDevicePreset.h"
#import "CAMHardwareSession.h"
#import "CAMVideoFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMHardwareDevice () <AVCapturePhotoCaptureDelegate,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate>

/// Underlying session that holds all AV inputs and outputs.
@property (readonly, nonatomic) CAMHardwareSession *session;

/// Scheduler to run all \c session mutations on.
@property (readonly, nonatomic) RACScheduler *scheduler;

/// Subject for sending video frames.
@property (readonly, nonatomic) RACSubject *videoFramesSubject;

/// Subject for sending video frames errors.
@property (readonly, nonatomic) RACSubject *videoFramesErrorsSubject;

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

/// Exposure duration. Affects both video stream (exposure and frame rate) and still photos.
@property (nonatomic) NSTimeInterval exposureDuration;

/// Minimal valid value for \c exposureDuration.
@property (nonatomic) NSTimeInterval minExposureDuration;

/// Maximal valid value for \c exposureDuration.
@property (nonatomic) NSTimeInterval maxExposureDuration;

/// ISO value.
@property (nonatomic) float ISO;

/// Minimal valid value for \c ISO.
@property (nonatomic) float minISO;

/// Maximal valid value for \c ISO.
@property (nonatomic) float maxISO;

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

/// Dictionary that maps unique id of the capture photo settings to the subscriber object.
@property (readonly, nonatomic) NSMutableDictionary<NSNumber *, id<RACSubscriber>>
    *uniqueIdToSubscriber;

@end

@implementation CAMHardwareDevice

@synthesize interfaceOrientation = _interfaceOrientation;
@synthesize gravityOrientation = _gravityOrientation;

- (instancetype)initWithSession:(CAMHardwareSession *)session
                   sessionQueue:(dispatch_queue_t)sessionQueue {
  if (self = [super init]) {
    _session = session;
    _scheduler = [[RACTargetQueueScheduler alloc] initWithName:nil targetQueue:sessionQueue];
    _videoFramesSubject = [RACSubject subject];
    _videoFramesErrorsSubject = [RACSubject subject];
    _audioFramesSubject = [RACSubject subject];
    _uniqueIdToSubscriber = [[NSMutableDictionary alloc] init];
    [self setupSessionDelegates];
    [self setupProperties];
  }
  return self;
}

- (void)setupSessionDelegates {
  @weakify(self);
  [self.scheduler schedule:^{
    @strongify(self);
    self.session.videoDelegate = self;
    self.session.audioDelegate = self;
  }];
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

  RAC(self, exposureDuration, @0) = [RACObserve(self, session.videoDevice.exposureDuration)
   map:^NSNumber *(NSValue *nativeExposureDurationValue) {
     CMTime nativeExposureDuration;
     [nativeExposureDurationValue getValue:&nativeExposureDuration];
     NSTimeInterval exposureDuration = CMTimeGetSeconds(nativeExposureDuration);
     return @(exposureDuration);
   }];

  RAC(self, minExposureDuration, @0) =
      [RACObserve(self, session.videoDevice.activeFormat.minExposureDuration)
       map:^NSNumber *(NSValue *nativeExposureDurationValue) {
         CMTime nativeExposureDuration;
         [nativeExposureDurationValue getValue:&nativeExposureDuration];
         NSTimeInterval exposureDuration = CMTimeGetSeconds(nativeExposureDuration);
         return @(exposureDuration);
       }];

  RAC(self, maxExposureDuration, @0) =
      [RACObserve(self, session.videoDevice.activeFormat.maxExposureDuration)
      map:^NSNumber *(NSValue *nativeExposureDurationValue) {
         CMTime nativeExposureDuration;
         [nativeExposureDurationValue getValue:&nativeExposureDuration];
         NSTimeInterval exposureDuration = CMTimeGetSeconds(nativeExposureDuration);
         return @(exposureDuration);
       }];

  RAC(self, ISO, @0) = RACObserve(self, session.videoDevice.ISO);

  RAC(self, minISO, @0) = RACObserve(self, session.videoDevice.activeFormat.minISO);

  RAC(self, maxISO, @0) = RACObserve(self, session.videoDevice.activeFormat.maxISO);
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

- (void)captureOutput:(AVCaptureOutput __unused *)captureOutput
  didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection __unused *)connection {
  NSString *dropReason = (__bridge NSString *)(CFStringRef)
      CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_DroppedFrameReason, NULL);
  NSError *error = [NSError lt_errorWithCode:CAMErrorCodeDroppedFrame
                                 description:@"%@", dropReason];
  [self.videoFramesErrorsSubject sendNext:error];
}

- (void)didOutputVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  [self fixOrientationInSampleBuffer:sampleBuffer];
  [self.videoFramesSubject sendNext:[[CAMVideoFrame alloc] initWithSampleBuffer:sampleBuffer]];
}

- (void)fixOrientationInSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  static const CFStringRef kOrientationKey = (__bridge CFStringRef)@"Orientation";

  NSNumber *currentOrientation =
      (__bridge NSNumber *)CMGetAttachment(sampleBuffer, kOrientationKey, NULL);
  if (![currentOrientation isKindOfClass:[NSNumber class]]) {
    return;
  }

  int fixedOrientation = [self fixedOrientationForOrientation:currentOrientation.intValue];

  CMSetAttachment(sampleBuffer, kOrientationKey, (__bridge CFNumberRef)@(fixedOrientation),
                  kCMAttachmentMode_ShouldPropagate);
}

/// When interfaceOrientation and gravityOrientation are not the same value (f.e. when interface
/// rotation is locked), the video frame will be oriented incorrectly. This can interfere with
/// features such as face detection. Mirroring the still output can break features such as face
/// tracking.
- (int)fixedOrientationForOrientation:(int)orientation {
  if (orientation < 1 || orientation > 8) {
    return orientation;
  }

  /// Maps an EXIF orientation value to the orientation value relatively rotated 90 degrees CCW.
  static const std::array<int, 9> kOrientationToRotatedOnceOrientation{{0, 6, 5, 8, 7, 4, 3, 2, 1}};

  /// Maps an EXIF orientation value to the orientation value relatively mirrored.
  static const std::array<int, 9> kOrientationToMirroredOrientation{{0, 2, 1, 4, 3, 6, 5, 8, 7}};

  NSInteger rotationsDiff =
      [self rotationsFromOrientation:self.interfaceOrientation] -
      [self rotationsFromOrientation:self.gravityOrientation];
  rotationsDiff = ((rotationsDiff % 4) + 4) % 4;

  int fixedOrientation = orientation;
  while (rotationsDiff-- > 0) {
    fixedOrientation = kOrientationToRotatedOnceOrientation[fixedOrientation];
  }

  if (self.session.videoConnection.videoMirrored) {
    fixedOrientation = kOrientationToMirroredOrientation[fixedOrientation];
  }

  return fixedOrientation;
}

- (NSInteger)rotationsFromOrientation:(UIInterfaceOrientation)orientation {
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      return 0;
    case UIInterfaceOrientationPortraitUpsideDown:
      return 2;
    case UIInterfaceOrientationLandscapeLeft:
      return 3;
    case UIInterfaceOrientationLandscapeRight:
      return 1;
    case UIInterfaceOrientationUnknown:
      return 0;
  }
}

- (void)didOutputAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  [self.audioFramesSubject sendNext:[[CAMAudioFrame alloc] initWithSampleBuffer:sampleBuffer]];
}

#pragma mark -
#pragma mark CAMVideoDevice
#pragma mark -

- (RACSignal *)setPixelFormat:(CAMPixelFormat *)pixelFormat {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    self.session.videoOutput.videoSettings = pixelFormat.videoSettings;
    if (@available(iOS 10.0, *)) {
      self.session.pixelFormat = pixelFormat;
    } else {
      self.session.stillOutput.outputSettings = pixelFormat.videoSettings;
    }
    return [RACSignal return:pixelFormat];
  }] subscribeOn:self.scheduler];
}

- (RACSignal *)stillFramesWithTrigger:(RACSignal *)trigger {
  @weakify(self);
  RACSignal *captureStillImage = [[RACSignal
      createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
        if (@available(iOS 10.0, *)) {
          [self capturePhotoAndSendToSuscriber:subscriber];
        } else {
          [self captureStillImageAndSendToSuscriber:subscriber];
        }
        return nil;
      }]
      subscribeOn:self.scheduler];

  return [[[trigger mapReplace:captureStillImage]
      concat]
      takeUntil:[self rac_willDeallocSignal]];
}

- (void)capturePhotoAndSendToSuscriber:(id<RACSubscriber>)subscriber API_AVAILABLE(ios(10.0)) {
  AVCapturePhotoSettings *photoSettings =
      [AVCapturePhotoSettings photoSettingsWithFormat:self.session.pixelFormat.videoSettings];
  photoSettings.flashMode = self.session.videoDevice.flashMode;
  photoSettings.highResolutionPhotoEnabled = YES;
  @synchronized(self.uniqueIdToSubscriber) {
    self.uniqueIdToSubscriber[@(photoSettings.uniqueID)] = subscriber;
  }
  [self.session.photoOutput capturePhotoWithSettings:photoSettings delegate:self];
}

- (void)captureStillImageAndSendToSuscriber:(id<RACSubscriber>)subscriber {
  [self.session.stillOutput
   captureStillImageAsynchronouslyFromConnection:self.session.stillConnection
   completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
     if (error) {
       [subscriber sendError:[NSError lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput
                                       underlyingError:error]];
     } else {
       CAMVideoFrame *frame = [[CAMVideoFrame alloc] initWithSampleBuffer:imageDataSampleBuffer];
       [subscriber sendNext:frame];
       [subscriber sendCompleted];
     }
   }];
}

- (RACSignal *)videoFrames {
  return self.videoFramesSubject;
}

- (RACSignal *)videoFramesErrors {
  return self.videoFramesErrorsSubject;
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  _interfaceOrientation = interfaceOrientation;
  if (interfaceOrientation != UIInterfaceOrientationUnknown) {
    AVCaptureVideoOrientation videoOrientation =
        [self videoOrientationForInterfaceOrientation:interfaceOrientation];
    self.session.videoConnection.videoOrientation = videoOrientation;
    self.session.previewLayer.connection.videoOrientation = videoOrientation;
  }
}

- (void)setGravityOrientation:(UIInterfaceOrientation)gravityOrientation {
  _gravityOrientation = gravityOrientation;
  if (gravityOrientation != UIInterfaceOrientationUnknown) {
    AVCaptureVideoOrientation videoOrientation =
        [self videoOrientationForInterfaceOrientation:gravityOrientation];
    self.session.stillConnection.videoOrientation = videoOrientation;
  }
}

- (AVCaptureVideoOrientation)videoOrientationForInterfaceOrientation:
    (UIInterfaceOrientation)interfaceOrientation {
  switch (interfaceOrientation) {
    case UIInterfaceOrientationPortrait:
      return AVCaptureVideoOrientationPortrait;
    case UIInterfaceOrientationPortraitUpsideDown:
      return AVCaptureVideoOrientationPortraitUpsideDown;
    case UIInterfaceOrientationLandscapeLeft:
      return AVCaptureVideoOrientationLandscapeLeft;
    case UIInterfaceOrientationLandscapeRight:
      return AVCaptureVideoOrientationLandscapeRight;
    case UIInterfaceOrientationUnknown:
      LTAssert(NO, @"Unsupported interface orientation");
  }
}

- (RACSignal *)subjectAreaChanged {
  return [[[[NSNotificationCenter defaultCenter]
      rac_addObserverForName:AVCaptureDeviceSubjectAreaDidChangeNotification object:nil]
      takeUntil:[self rac_willDeallocSignal]]
      mapReplace:[RACUnit defaultUnit]];
}

#pragma mark -
#pragma mark AVCapturePhotoCaptureDelegate
#pragma mark -

- (void)captureOutput:(AVCapturePhotoOutput * __unused)captureOutput
    didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer
    previewPhotoSampleBuffer:(nullable CMSampleBufferRef __unused)previewPhotoSampleBuffer
    resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
    bracketSettings:(nullable AVCaptureBracketedStillImageSettings * __unused)bracketSettings
    error:(nullable NSError *)error API_AVAILABLE(ios(10.0)) {
  id<RACSubscriber> subscriber;
  @synchronized(self.uniqueIdToSubscriber) {
    subscriber = self.uniqueIdToSubscriber[@(resolvedSettings.uniqueID)];
  }

  if (error) {
    [subscriber sendError:[NSError lt_errorWithCode:CAMErrorCodeFailedCapturingFromStillOutput
                                    underlyingError:error]];
  } else {
    CAMVideoFrame *frame = [[CAMVideoFrame alloc] initWithSampleBuffer:photoSampleBuffer];
    [subscriber sendNext:frame];
    [subscriber sendCompleted];
  }
}

- (void)captureOutput:(AVCapturePhotoOutput * __unused)captureOutput
    didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
    error:(nullable NSError * __unused)error API_AVAILABLE(ios(10.0)) {
  @synchronized(self.uniqueIdToSubscriber) {
    [self.uniqueIdToSubscriber removeObjectForKey:@(resolvedSettings.uniqueID)];
  }
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
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setFocusMode:mode point:point error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (BOOL)setFocusMode:(AVCaptureFocusMode)mode point:(CGPoint)point
               error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isFocusModeSupported:mode] &&
        (mode == AVCaptureFocusModeLocked || device.isFocusPointOfInterestSupported)) {
      if (mode != AVCaptureFocusModeLocked) {
        device.focusPointOfInterest = point;
      }
      device.focusMode = mode;

      return YES;
    } else {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
      }
      return NO;
    }
  } error:error];
}

- (RACSignal *)setLockedFocusPosition:(CGFloat)lensPosition {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (lensPosition > 1 || lensPosition < 0 || !std::isfinite(lensPosition)) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported
                                    description:@"Lens position %g is out of range [0, 1]",
                       lensPosition];
        }
        return NO;
      }

      if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
        [device setFocusModeLockedWithLensPosition:lensPosition
                                 completionHandler:^(CMTime __unused syncTime) {
                                   [subscriber sendNext:@(lensPosition)];
                                   [subscriber sendCompleted];
                                 }];
        return YES;
      } else {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFocusSettingUnsupported];
        }
        return NO;
      }
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }] subscribeOn:self.scheduler];
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
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setExposureMode:mode point:point error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (BOOL)setExposureMode:(AVCaptureExposureMode)mode point:(CGPoint)point
                  error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isExposureModeSupported:mode] &&
        (CGPointIsNull(point) || device.isExposurePointOfInterestSupported)) {
      if (!CGPointIsNull(point)) {
        device.exposurePointOfInterest = point;
      }
      device.exposureMode = mode;

      return YES;
    } else {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported];
      }
      return NO;
    }
  } error:error];
}

- (RACSignal *)setExposureCompensation:(float)value {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (value > device.maxExposureTargetBias || value < device.minExposureTargetBias ||
          !std::isfinite(value)) {
        NSString *description =
            [NSString stringWithFormat:@"Exposure compensation value %g is out of range [%g, %g]",
                                       value, device.minExposureTargetBias,
                                       device.maxExposureTargetBias];
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported
                                    description:@"%@", description];
        }
        return NO;
      }

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
  }] subscribeOn:self.scheduler];
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration {
  CMTime nativeExposureDuration = CMTimeMakeWithSeconds(exposureDuration, 1000000);
  return [[self setNativeExposureDuration:nativeExposureDuration ISO:AVCaptureISOCurrent]
          mapReplace:@(exposureDuration)];
}

- (RACSignal *)setManualExposureWithISO:(float)ISO {
  return [[self setNativeExposureDuration:AVCaptureExposureDurationCurrent ISO:ISO]
          mapReplace:@(ISO)];
}

- (RACSignal *)setManualExposureWithDuration:(NSTimeInterval)exposureDuration andISO:(float)ISO {
  CMTime nativeExposureDuration = CMTimeMakeWithSeconds(exposureDuration, 1000000);
  return [[self setNativeExposureDuration:nativeExposureDuration ISO:ISO]
          mapReplace:RACTuplePack(@(exposureDuration), @(ISO))];
}

- (RACSignal *)setNativeExposureDuration:(CMTime)nativeExposureDuration ISO:(float)ISO {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (ISO != AVCaptureISOCurrent && (ISO < device.activeFormat.minISO ||
                                         ISO > device.activeFormat.maxISO)) {
        NSString *description = [NSString stringWithFormat:@"ISO value %g is out of range [%g, %g]",
                                 ISO, device.activeFormat.minISO, device.activeFormat.maxISO];
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported
                                    description:@"%@", description];
        }
        return NO;
      }
      if (CMTimeCompare(nativeExposureDuration, AVCaptureExposureDurationCurrent) != 0 &&
          (CMTimeCompare(nativeExposureDuration, device.activeFormat.minExposureDuration) < 0 ||
           CMTimeCompare(nativeExposureDuration, device.activeFormat.maxExposureDuration) > 0)) {
        NSString *description = [NSString stringWithFormat:@"Exposure duration value %g is "
                                 "out of range [%g, %g]", CMTimeGetSeconds(nativeExposureDuration),
                                 CMTimeGetSeconds(device.activeFormat.maxExposureDuration),
                                 CMTimeGetSeconds(device.activeFormat.maxExposureDuration)];
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported
                                    description:@"%@", description];
        }
        return NO;
      }

      @try {
        [device setExposureModeCustomWithDuration:nativeExposureDuration ISO:ISO
                                completionHandler:^(CMTime __unused syncTime) {
                                  [subscriber sendNext:[RACUnit defaultUnit]];
                                  [subscriber sendCompleted];
                                }];
      } @catch (NSException *exception) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeExposureSettingUnsupported
                                    description:@"%@", exception];
        }
        return NO;
      }

      return YES;
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }] subscribeOn:self.scheduler];
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
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setWhiteBalanceMode:mode error:&error];
    return success ? [RACSignal empty] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (BOOL)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode
                      error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  return [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if ([device isWhiteBalanceModeSupported:mode]) {
      device.whiteBalanceMode = mode;
      return YES;
    } else {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
      }
      return NO;
    }
  } error:error];
}

- (RACSignal *)setLockedWhiteBalanceWithTemperature:(float)temperature tint:(float)tint {
  @weakify(self);
  return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
        AVCaptureWhiteBalanceGains gains =
            [device deviceWhiteBalanceGainsForTemperatureAndTintValues:{temperature, tint}];

        if (gains.redGain < 1 || gains.redGain > device.maxWhiteBalanceGain ||
            !std::isfinite(gains.redGain)) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported
                                      description:@"Red gain %g is out of range [1, %g]",
                         gains.redGain, device.maxWhiteBalanceGain];
          }
          return NO;
        }

        if (gains.greenGain < 1 || gains.greenGain > device.maxWhiteBalanceGain ||
            !std::isfinite(gains.greenGain)) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported
                                      description:@"Green gain %g is out of range [1, %g]",
                         gains.greenGain, device.maxWhiteBalanceGain];
          }
          return NO;
        }

        if (gains.blueGain < 1 || gains.blueGain > device.maxWhiteBalanceGain ||
            !std::isfinite(gains.blueGain)) {
          if (errorPtr) {
            *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported
                                      description:@"Blue gain %g is out of range [1, %g]",
                         gains.blueGain, device.maxWhiteBalanceGain];
          }
          return NO;
        }

        [device
         setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains
         completionHandler:^(CMTime) {
           [subscriber sendNext:RACTuplePack(@(temperature), @(tint))];
           [subscriber sendCompleted];
         }];
        return YES;
      } else {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeWhiteBalanceSettingUnsupported];
        }
        return NO;
      }
    } error:&error];

    if (!success) {
      [subscriber sendError:error];
    }

    return nil;
  }] subscribeOn:self.scheduler];
}

#pragma mark -
#pragma mark CAMZoomDevice
#pragma mark -

- (RACSignal *)setZoom:(CGFloat)zoomFactor {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (zoomFactor > self.maxZoomFactor || zoomFactor < self.minZoomFactor ||
          !std::isfinite(zoomFactor)) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeZoomSettingUnsupported
                                    description:@"Zoom factor %g is out of range [%g, %g]",
                       zoomFactor, self.minZoomFactor, self.maxZoomFactor];
        }
        return NO;
      }

      device.videoZoomFactor = zoomFactor;
      return YES;
    } error:&error];
    return success ? [RACSignal return:@(zoomFactor)] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float)rate {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    AVCaptureDevice *device = self.session.videoDevice;
    NSError *error;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if (zoomFactor > self.maxZoomFactor || zoomFactor < self.minZoomFactor ||
          !std::isfinite(zoomFactor)) {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeZoomSettingUnsupported
                                    description:@"Zoom factor %g is out of range [%g, %g]",
                       zoomFactor, self.minZoomFactor, self.maxZoomFactor];
        }
        return NO;
      }

      [device rampToVideoZoomFactor:zoomFactor withRate:rate];
      return YES;
    } error:&error];
    return success ? [[self rampingZoom:device] mapReplace:@(zoomFactor)] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
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
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    AVCaptureDevice *device = self.session.videoDevice;
    BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
      if ([device isFlashModeSupported:flashMode]) {
        device.flashMode = flashMode;
        return YES;
      } else {
        if (errorPtr) {
          *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeFlashModeSettingUnsupported];
        }
        return NO;
      }
    } error:&error];
    return success ? [RACSignal return:@(flashMode)] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

#pragma mark -
#pragma mark CAMTorchDevice
#pragma mark -

- (RACSignal *)setTorchLevel:(float)torchLevel {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setTorchLevel:torchLevel error:&error];
    return success ? [RACSignal return:@(torchLevel)] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (BOOL)setTorchLevel:(float)torchLevel error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if (torchLevel > 1 || torchLevel < 0 || !std::isfinite(torchLevel)) {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported
                                  description:@"Torch level %g is out of range [0, 1]", torchLevel];
      }
      return NO;
    }

    if (torchLevel == 0) {
      return [self setDeviceTorchOff:device error:errorPtr];
    } else {
      return [self setDeviceTorchOn:device withLevel:torchLevel error:errorPtr];
    }
  } error:error];
  return success;
}

- (BOOL)setDeviceTorchOff:(AVCaptureDevice *)device error:(NSError * __autoreleasing *)errorPtr {
  if (![device isTorchModeSupported:AVCaptureTorchModeOff]) {
    if (errorPtr) {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
    }
    return NO;
  }
  device.torchMode = AVCaptureTorchModeOff;
  return YES;
}

- (BOOL)setDeviceTorchOn:(AVCaptureDevice *)device withLevel:(float)torchLevel
                   error:(NSError * __autoreleasing *)errorPtr {
  if (![device isTorchModeSupported:AVCaptureTorchModeOn]) {
    if (errorPtr) {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
    }
    return NO;
  }
  NSError *setLevelError;
  BOOL torchWasSet = [device setTorchModeOnWithLevel:torchLevel error:&setLevelError];
  if (setLevelError || !torchWasSet) {
    if (errorPtr) {
      *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported
                            underlyingError:setLevelError];
    }
    return NO;
  }
  return YES;
}

- (RACSignal *)setTorchMode:(AVCaptureTorchMode)torchMode {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self setTorchMode:torchMode error:&error];
    return success ? [RACSignal return:@(torchMode)] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

- (BOOL)setTorchMode:(AVCaptureTorchMode)torchMode error:(NSError * __autoreleasing *)error {
  AVCaptureDevice *device = self.session.videoDevice;
  BOOL success = [device cam_performWhileLocked:^BOOL(NSError **errorPtr) {
    if (![device isTorchModeSupported:torchMode]) {
      if (errorPtr) {
        *errorPtr = [NSError lt_errorWithCode:CAMErrorCodeTorchModeSettingUnsupported];
      }
      return NO;
    }
    device.torchMode = torchMode;
    return YES;
  } error:error];
  return success;
}

#pragma mark -
#pragma mark CAMFlipDevice
#pragma mark -

- (RACSignal *)setCamera:(CAMDeviceCamera *)camera {
  @weakify(self);
  return [[RACSignal defer:^RACSignal *{
    @strongify(self);
    NSError *error;
    BOOL success = [self.session setCamera:camera error:&error];
    return success ? [RACSignal return:camera] : [RACSignal error:error];
  }] subscribeOn:self.scheduler];
}

@end

NS_ASSUME_NONNULL_END
