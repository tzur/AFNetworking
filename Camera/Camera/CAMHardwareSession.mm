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

/// Photo output attached to this session.
@property (readwrite, nonatomic) AVCapturePhotoOutput *photoOutput;

/// Photo connection between \c videoInput and \c photoOutput.
@property (readwrite, nonatomic) AVCaptureConnection *photoConnection;

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
  AVCaptureVideoOrientation videoOrientation = self.videoConnection.videoOrientation;
  AVCaptureVideoOrientation photoOrientation = self.photoConnection.videoOrientation;
  AVCaptureVideoOrientation previewOrientation = self.previewLayer.connection.videoOrientation;

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
  [self updatePhotoConnection];
  self.videoConnection.videoOrientation = videoOrientation;
  self.photoConnection.videoOrientation = photoOrientation;
  self.previewLayer.connection.videoOrientation = previewOrientation;

  return YES;
}

- (BOOL)setupVideoOutputWithError:(NSError * __autoreleasing *)error {
  AVCaptureVideoOrientation videoOrientation = self.videoConnection.videoOrientation;

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
  self.videoConnection.videoOrientation = videoOrientation;

  return YES;
}

- (void)updateVideoConnection {
  self.videoConnection = self.videoOutput.connections.firstObject;
  if (self.videoConnection.isVideoMirroringSupported &&
      self.videoDevice.position == AVCaptureDevicePositionFront) {
    self.videoConnection.videoMirrored = YES;
  }
}

- (BOOL)setupPhotoOutputWithPixelFormat:(CAMPixelFormat *)pixelFormat
                                  error:(NSError * __autoreleasing *)error {
  AVCaptureVideoOrientation photoOrientation = self.photoConnection.videoOrientation;

  if (self.photoOutput) {
    [self.session removeOutput:self.photoOutput];
  }

  self.photoOutput = [[AVCapturePhotoOutput alloc] init];
  self.photoOutput.highResolutionCaptureEnabled = YES;
  self.pixelFormat = pixelFormat;

  if (![self.session canAddOutput:self.photoOutput]) {
    if (error) {
      *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingPhotoOutput];
    }
    return NO;
  }
  [self.session addOutput:self.photoOutput];

  [self updatePhotoConnection];
  self.photoConnection.videoOrientation = photoOrientation;

  return YES;
}

- (void)updatePhotoConnection {
  self.photoConnection = self.photoOutput.connections.firstObject;
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

  [self updateAudioConnection];

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

  [self updateAudioConnection];

  return YES;
}

- (void)updateAudioConnection {
  self.audioConnection = self.audioOutput.connections.firstObject;
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

- (void)dealloc {
  if (self.session.running) {
    [self.session stopRunning];
  }

  [self.videoOutput setSampleBufferDelegate:nil queue:NULL];
  [self.audioOutput setSampleBufferDelegate:nil queue:NULL];

  [self.session beginConfiguration];
  for (AVCaptureInput *input in self.session.inputs) {
    [self.session removeInput:input];
  }
  for (AVCaptureOutput *output in self.session.outputs) {
    [self.session removeOutput:output];
  }
  [self.session commitConfiguration];
}

@end

NS_ASSUME_NONNULL_END
