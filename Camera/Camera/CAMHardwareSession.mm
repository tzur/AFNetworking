// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMHardwareSession.h"

#import "CAMFormatStrategy.h"
#import "NSErrorCodes+Camera.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAMHardwareSession ()

/// Preview layer attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureVideoPreviewLayer *previewLayer;

/// Video device attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureDevice *videoDevice;

/// Video input attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *videoInput;

/// Video output attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureVideoDataOutput *videoOutput;

/// Video connection between \c videoInput and \c videoOutput, or \c nil before both are attached.
@property (readwrite, nonatomic, nullable) AVCaptureConnection *videoConnection;

/// Still output attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureStillImageOutput *stillOutput;

/// Still connection between \c videoInput and \c stillOutput, or \c nil before both are attached.
@property (readwrite, nonatomic, nullable) AVCaptureConnection *stillConnection;

/// Audio device attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureDevice *audioDevice;

/// Audio input attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureDeviceInput *audioInput;

/// Audio output attached to this session, or \c nil before one is attached.
@property (readwrite, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;

/// Audio connection between \c audioInput and \c audioOutput, or \c nil before both are attached.
@property (readwrite, nonatomic, nullable) AVCaptureConnection *audioConnection;

@end

@implementation CAMHardwareSession

- (instancetype)init {
  if (self = [super init]) {
    _session = [[AVCaptureSession alloc] init];
  }
  return self;
}

- (void)createPreviewLayer {
  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
}

- (BOOL)setupVideoInputWithDevice:(AVCaptureDevice *)device
                   formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                            error:(NSError * __autoreleasing *)error {
  if (!device) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeMissingVideoDevice];
    return NO;
  }

  LTParameterAssert(error, @"error output pointer must be non-null");
  LTParameterAssert([device hasMediaType:AVMediaTypeVideo], @"device must provide video");
  NSError *internalError;
  AVCaptureVideoOrientation currentOrientation = self.videoConnection.videoOrientation;

  if (self.videoInput) {
    [self.session removeInput:self.videoInput];
  }

  self.videoDevice = device;
  BOOL locked = [self.videoDevice lockForConfiguration:&internalError];
  if (!locked) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedLockingVideoDevice
                       underlyingError:internalError];
    return NO;
  }
  AVCaptureDeviceFormat *format = [formatStrategy formatFrom:self.videoDevice.formats];
  if (!format) {
    [self.videoDevice unlockForConfiguration];
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedConfiguringVideoDevice];
    return NO;
  }
  self.videoDevice.activeFormat = format;
  self.videoDevice.subjectAreaChangeMonitoringEnabled = YES;
  [self.videoDevice unlockForConfiguration];

  self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice
                                                          error:&internalError];
  if (internalError) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedCreatingVideoInput
                       underlyingError:internalError];
    return NO;
  }
  if (![self.session canAddInput:self.videoInput]) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingVideoInput];
    return NO;
  }
  [self.session addInput:self.videoInput];

  self.videoConnection = self.videoOutput.connections.firstObject;
  self.videoConnection.videoOrientation = currentOrientation;
  self.stillConnection = self.stillOutput.connections.firstObject;
  self.stillConnection.videoOrientation = currentOrientation;

  return YES;
}

- (BOOL)setupVideoOutputWithError:(NSError * __autoreleasing *)error {
  LTParameterAssert(error, @"error output pointer must be non-null");
  AVCaptureVideoOrientation currentOrientation = self.videoConnection.videoOrientation;

  if (self.videoOutput) {
    [self.session removeOutput:self.videoOutput];
  }

  self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
  if (![self.session canAddOutput:self.videoOutput]) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingVideoOutput];
    return NO;
  }
  [self.session addOutput:self.videoOutput];

  self.videoConnection = self.videoOutput.connections.firstObject;
  self.videoConnection.videoOrientation = currentOrientation;

  return YES;
}

- (BOOL)setupStillOutputWithError:(NSError * __autoreleasing *)error {
  LTParameterAssert(error, @"error output pointer must be non-null");
  AVCaptureVideoOrientation currentOrientation = self.videoConnection.videoOrientation;

  if (self.stillOutput) {
    [self.session removeOutput:self.stillOutput];
  }

  self.stillOutput = [[AVCaptureStillImageOutput alloc] init];
  if (![self.session canAddOutput:self.stillOutput]) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingStillOutput];
    return NO;
  }
  [self.session addOutput:self.stillOutput];

  self.stillConnection = self.stillOutput.connections.firstObject;
  self.stillConnection.videoOrientation = currentOrientation;

  return YES;
}

- (BOOL)setupAudioInputWithDevice:(AVCaptureDevice *)device
                            error:(NSError * __autoreleasing *)error {
  if (!device) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeMissingAudioDevice];
    return NO;
  }

  LTParameterAssert(error, @"error output pointer must be non-null");
  LTParameterAssert([device hasMediaType:AVMediaTypeAudio], @"device must provide audio");
  NSError *internalError;

  if (self.audioInput) {
    [self.session removeInput:self.audioInput];
  }

  self.audioDevice = device;

  self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevice
                                                          error:&internalError];
  if (internalError) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedCreatingAudioInput
                       underlyingError:internalError];
    return NO;
  }
  if (![self.session canAddInput:self.audioInput]) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingAudioInput];
    return NO;
  }
  [self.session addInput:self.audioInput];

  self.audioConnection = self.audioOutput.connections.firstObject;

  return YES;
}

- (BOOL)setupAudioOutputWithError:(NSError * __autoreleasing *)error {
  LTParameterAssert(error, @"error output pointer must be non-null");

  if (self.audioOutput) {
    [self.session removeOutput:self.audioOutput];
  }

  self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
  if (![self.session canAddOutput:self.audioOutput]) {
    *error = [NSError lt_errorWithCode:CAMErrorCodeFailedAttachingAudioOutput];
    return NO;
  }
  [self.session addOutput:self.audioOutput];

  self.audioConnection = self.audioOutput.connections.firstObject;

  return YES;
}

@end

@implementation CAMHardwareSession (ForTesting)

- (instancetype)initWithSession:(AVCaptureSession *)session {
  if (self = [super init]) {
    _session = session;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
