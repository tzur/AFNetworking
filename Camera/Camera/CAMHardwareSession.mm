// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareSession.h"

#import "CAMDevicePreset.h"
#import "CAMFormatStrategy.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMHardwareSession ()

/// Preset used to initialize this device.
@property (readonly, nonatomic) CAMDevicePreset *preset;

/// The \c AVCaptureSession object managed by the receiver.
@property (readonly, nonatomic) AVCaptureSession *session;

/// Preview layer attached to this session.
@property (readwrite, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

/// Video device attached to this session.
@property (readwrite, nonatomic) AVCaptureDevice *videoDevice;

/// Video input attached to this session.
@property (readwrite, nonatomic) AVCaptureDeviceInput *videoInput;

/// Video output attached to this session.
@property (readwrite, nonatomic) AVCaptureVideoDataOutput *videoOutput;

/// Video connection between \c videoInput and \c videoOutput.
@property (readwrite, nonatomic) AVCaptureConnection *videoConnection;

/// Still output attached to this session.
@property (readwrite, nonatomic) AVCaptureStillImageOutput *stillOutput;

/// Still connection between \c videoInput and \c stillOutput.
@property (readwrite, nonatomic) AVCaptureConnection *stillConnection;

/// Audio device attached to this session, or \c nil if audio is not enabled in the preset.
@property (readwrite, nonatomic, nullable) AVCaptureDevice *audioDevice;

/// Audio input attached to this session, or \c nil if audio is not enabled in the preset.
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *audioInput;

/// Audio output attached to this session, or \c nil if audio is not enabled in the preset.
@property (readwrite, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;

/// Audio connection between \c audioInput and \c audioOutput, or \c nil if audio is not enabled
/// in the preset.
@property (readwrite, nonatomic, nullable) AVCaptureConnection *audioConnection;

@end

@implementation CAMHardwareSession

- (instancetype)initWithPreset:(CAMDevicePreset *)preset session:(AVCaptureSession *)session {
  if (self = [super init]) {
    _preset = preset;
    _session = session;
  }
  return self;
}

- (void)createPreviewLayer {
  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
  self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  self.previewLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
}

- (BOOL)setCamera:(CAMDeviceCamera *)camera error:(NSError * __autoreleasing *)error {
  [self.session beginConfiguration];
  BOOL success = [self setupVideoInputWithDevice:camera.device
                                  formatStrategy:self.preset.formatStrategy
                                           error:error];
  [self.session commitConfiguration];
  return success;
}

- (BOOL)setupVideoInputWithDevice:(AVCaptureDevice *)device
                   formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                            error:(NSError * __autoreleasing *)error {
  if (!device) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeMissingVideoDevice];
    }
    return NO;
  }

  LTParameterAssert([device hasMediaType:AVMediaTypeVideo], @"device must provide video");
  NSError *internalError;
  AVCaptureVideoOrientation currentStillOrientation = self.stillConnection.videoOrientation;

  if (self.videoInput) {
    [self.session removeInput:self.videoInput];
  }

  self.videoDevice = device;
  BOOL locked = [self.videoDevice lockForConfiguration:&internalError];
  if (!locked) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedLockingVideoDevice
                         underlyingError:internalError];
    }
    return NO;
  }
  AVCaptureDeviceFormat *format = [formatStrategy formatFrom:self.videoDevice.formats];
  if (!format) {
    [self.videoDevice unlockForConfiguration];
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedConfiguringVideoDevice];
    }
    return NO;
  }
  self.videoDevice.activeFormat = format;
  self.videoDevice.subjectAreaChangeMonitoringEnabled = YES;
  [self.videoDevice unlockForConfiguration];

  self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice
                                                          error:&internalError];
  if (internalError) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedCreatingVideoInput
                         underlyingError:internalError];
    }
    return NO;
  }
  if (![self.session canAddInput:self.videoInput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingVideoInput];
    }
    return NO;
  }
  [self.session addInput:self.videoInput];

  [self updateVideoConnection];
  self.stillConnection = self.stillOutput.connections.firstObject;
  self.stillConnection.videoOrientation = currentStillOrientation;

  return YES;
}

- (void)updateVideoConnection {
  self.videoConnection = self.videoOutput.connections.firstObject;
  self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
  if (self.videoConnection.isVideoMirroringSupported &&
      self.videoDevice.position == AVCaptureDevicePositionFront) {
    self.videoConnection.videoMirrored = YES;
  }
}

- (BOOL)setupVideoOutputWithError:(NSError * __autoreleasing *)error {
  if (self.videoOutput) {
    [self.session removeOutput:self.videoOutput];
  }

  self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  if (![self.session canAddOutput:self.videoOutput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingVideoOutput];
    }
    return NO;
  }
  [self.session addOutput:self.videoOutput];

  [self updateVideoConnection];

  return YES;
}

- (BOOL)setupStillOutputWithError:(NSError * __autoreleasing *)error {
  AVCaptureVideoOrientation currentStillOrientation = self.stillConnection.videoOrientation;

  if (self.stillOutput) {
    [self.session removeOutput:self.stillOutput];
  }

  self.stillOutput = [[AVCaptureStillImageOutput alloc] init];
  if (![self.session canAddOutput:self.stillOutput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingStillOutput];
    }
    return NO;
  }
  [self.session addOutput:self.stillOutput];

  self.stillConnection = self.stillOutput.connections.firstObject;
  self.stillConnection.videoOrientation = currentStillOrientation;

  return YES;
}

- (BOOL)setupAudioInputWithDevice:(AVCaptureDevice *)device
                            error:(NSError * __autoreleasing *)error {
  if (!device) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeMissingAudioDevice];
    }
    return NO;
  }

  LTParameterAssert([device hasMediaType:AVMediaTypeAudio], @"device must provide audio");
  NSError *internalError;

  if (self.audioInput) {
    [self.session removeInput:self.audioInput];
  }

  self.audioDevice = device;

  self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice
                                                          error:&internalError];
  if (internalError) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedCreatingAudioInput
                         underlyingError:internalError];
    }
    return NO;
  }
  if (![self.session canAddInput:self.audioInput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingAudioInput];
    }
    return NO;
  }
  [self.session addInput:self.audioInput];

  self.audioConnection = self.audioOutput.connections.firstObject;

  return YES;
}

- (BOOL)setupAudioOutputWithError:(NSError * __autoreleasing *)error {

  if (self.audioOutput) {
    [self.session removeOutput:self.audioOutput];
  }

  self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
  if (![self.session canAddOutput:self.audioOutput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingAudioOutput];
    }
    return NO;
  }
  [self.session addOutput:self.audioOutput];

  self.audioConnection = self.audioOutput.connections.firstObject;

  return YES;
}

- (void)setVideoDelegate:(nullable id<AVCaptureVideoDataOutputSampleBufferDelegate>)videoDelegate {
  _videoDelegate = videoDelegate;
  [self.session beginConfiguration];
  [self.videoOutput setSampleBufferDelegate:videoDelegate queue:self.preset.outputQueue];
  [self.session commitConfiguration];
}

- (void)setAudioDelegate:(nullable id<AVCaptureAudioDataOutputSampleBufferDelegate>)audioDelegate {
  _audioDelegate = audioDelegate;
  [self.session beginConfiguration];
  [self.audioOutput setSampleBufferDelegate:audioDelegate queue:self.preset.outputQueue];
  [self.session commitConfiguration];
}

@end

@implementation CAMHardwareSessionFactory

+ (RACSignal *)sessionWithPreset:(CAMDevicePreset *)preset {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    CAMHardwareSession *session = [[CAMHardwareSession alloc]
        initWithPreset:preset session:[[AVCaptureSession alloc] init]];
    NSError *error;
    BOOL success = [self configureSession:session withPreset:preset error:&error];
    if (success) {
      [subscriber sendNext:session];
      [subscriber sendCompleted];
    } else {
      [subscriber sendError:error];
    }
    return nil;
  }];
}

+ (BOOL)configureSession:(CAMHardwareSession *)session withPreset:(CAMDevicePreset *)preset
                   error:(NSError * __autoreleasing *)error {
  BOOL success;

  [session createPreviewLayer];
  [session.session beginConfiguration];
  session.session.sessionPreset = AVCaptureSessionPresetInputPriority;

  success = [session setupVideoInputWithDevice:preset.camera.device
                                formatStrategy:preset.formatStrategy error:error] &&
      [session setupVideoOutputWithError:error];
  if (!success) {
    return NO;
  }
  session.videoOutput.videoSettings = preset.pixelFormat.videoSettings;

  success = [session setupStillOutputWithError:error];
  if (!success) {
    return NO;
  }

  if (preset.enableAudio) {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    success = [session setupAudioInputWithDevice:device error:error] &&
        [session setupAudioOutputWithError:error];
    if (!success) {
      return NO;
    }
  }

  [session.session commitConfiguration];
  [session.session startRunning];

  return YES;
}

@end

NS_ASSUME_NONNULL_END
