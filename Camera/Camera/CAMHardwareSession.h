// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

#import "CAMDevicePreset.h"

NS_ASSUME_NONNULL_BEGIN

/// Thin wrapper around a \c AVCaptureSession object, with methods for assisting in initializing
/// it and accessing its properties.
///
/// All methods operate synchronously on the current queue. It's the caller's responsibility to
/// make sure the main queue is not blocked.
@interface CAMHardwareSession : NSObject

/// Creates a \c AVCaptureVideoPreviewLayer and attaches it to the session.
///
/// After calling this method, the layer can be accessed via \c previewLayer.
- (void)createPreviewLayer;

/// Configures \c device with a format according to \c formatStrategy, then creates a video input
/// with it and attaches it to the session. If a video input already exists, it is removed first.
/// If an error occurs while configuring \c device or creating the video input, \c NO is returned
/// and \c error is populated with an appropriate error.
///
/// Raises \c NSInvalidArgumentException if \c device is not a video device.
///
/// After calling this method, \c device can be accessed via \c videoDevice, the video input via
/// \c videoInput, and the video connection (if it exists) via \c videoConnection.
- (BOOL)setupVideoInputWithDevice:(AVCaptureDevice *)device
                   formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                            error:(NSError **)error;

/// Creates a \c AVCaptureVideoDataOutput and attaches it to the session. If a video output already
/// exists, it is removed first. If an error occurs, \c NO is returned and \c error is populated
/// with an appropriate error.
///
/// After calling this method, the video output can be accessed via \c videoOutput, and the video
/// connection (if it exists) via \c videoConnection.
- (BOOL)setupVideoOutputWithError:(NSError **)error;

/// Creates a \c AVCaptureStillImageOutput and attaches it to the session. If a still output already
/// exists, it is removed first. If an error occurs, \c NO is returned and \c error is populated
/// with an appropriate error.
///
/// After calling this method, the still output can be accessed via \c stillOutput, and the still
/// connection (if it exists) via \c stillConnection.
- (BOOL)setupStillOutputWithError:(NSError **)error;

/// Creates an audio input with the given audio device and attaches it to the session. If an audio
/// input already exists, it is removed first. If an error occurs, \c NO is returned and \c error is
/// populated with an appropriate error.
///
/// Raises \c NSInvalidArgumentException if \c device is not an audio device.
///
/// After calling this method, the audio device can be accessed via \c audioDevice, the audio input
/// via \c audioInput, and the audio connection (if it exists) via \c audioConnection.
- (BOOL)setupAudioInputWithDevice:(AVCaptureDevice *)device error:(NSError **)error;

/// Creates a \c AVCaptureAudioDataOutput and attaches it to the session. If an audio output already
/// exists, it is removed first. If an error occurs, \c NO is returned and \c error is populated
/// with an appropriate error.
///
/// After calling this method, the audio output can be accessed via \c audioOutput, and the audio
/// connection (if it exists) via \c audioConnection.
- (BOOL)setupAudioOutputWithError:(NSError **)error;

/// The \c AVCaptureSession object managed by the receiver.
@property (readonly, nonatomic) AVCaptureSession *session;

/// Preview layer attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureVideoPreviewLayer *previewLayer;

/// Video device attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureDevice *videoDevice;

/// Video input attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureDeviceInput *videoInput;

/// Video output attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureVideoDataOutput *videoOutput;

/// Video connection between \c videoInput and \c videoOutput, or \c nil before both are attached.
@property (readonly, nonatomic, nullable) AVCaptureConnection *videoConnection;

/// Still output attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureStillImageOutput *stillOutput;

/// Still connection between \c videoInput and \c stillOutput, or \c nil before both are attached.
@property (readonly, nonatomic, nullable) AVCaptureConnection *stillConnection;

/// Audio device attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureDevice *audioDevice;

/// Audio input attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureDeviceInput *audioInput;

/// Audio output attached to this session, or \c nil before one is attached.
@property (readonly, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;

/// Audio connection between \c audioInput and \c audioOutput, or \c nil before both are attached.
@property (readonly, nonatomic, nullable) AVCaptureConnection *audioConnection;

@end

NS_ASSUME_NONNULL_END
