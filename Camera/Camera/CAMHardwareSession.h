// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

@class CAMDeviceCamera, CAMDevicePreset;

@protocol CAMFormatStrategy;

NS_ASSUME_NONNULL_BEGIN

/// Thin wrapper around a \c AVCaptureSession object, with methods for assisting in initializing
/// it and accessing its properties.
///
/// All methods operate synchronously on the current queue. It's the caller's responsibility to
/// make sure the main queue is not blocked.
@interface CAMHardwareSession : NSObject

/// Unavailable. Use \c CAMHardwareSessionFactory instead.
- (instancetype)init NS_UNAVAILABLE;

/// Updates the session to use the given \c camera for video input. This includes configuring the
/// underlying device, creating a video input and attaching it to the session. The current video
/// input is removed. If an error occurs at any point, \c NO is returned and \c error is populated
/// with an appropriate error.
///
/// After calling this method, \c videoDevice, \c videoInput, and \c videoConnection are updated.
- (BOOL)setCamera:(CAMDeviceCamera *)camera error:(NSError **)error;

/// Preview layer attached to this session.
@property (readonly, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

/// Video device attached to this session.
@property (readonly, nonatomic) AVCaptureDevice *videoDevice;

/// Video input attached to this session.
@property (readonly, nonatomic) AVCaptureDeviceInput *videoInput;

/// Video output attached to this session.
@property (readonly, nonatomic) AVCaptureVideoDataOutput *videoOutput;

/// Video connection between \c videoInput and \c videoOutput.
@property (readonly, nonatomic) AVCaptureConnection *videoConnection;

/// Still output attached to this session.
@property (readonly, nonatomic) AVCaptureStillImageOutput *stillOutput;

/// Still connection between \c videoInput and \c stillOutput.
@property (readonly, nonatomic) AVCaptureConnection *stillConnection;

/// Audio device attached to this session, or \c nil if audio is not enabled in the preset.
@property (readonly, nonatomic, nullable) AVCaptureDevice *audioDevice;

/// Audio input attached to this session, or \c nil if audio is not enabled in the preset.
@property (readonly, nonatomic, nullable) AVCaptureDeviceInput *audioInput;

/// Audio output attached to this session, or \c nil if audio is not enabled in the preset.
@property (readonly, nonatomic, nullable) AVCaptureAudioDataOutput *audioOutput;

/// Audio connection between \c audioInput and \c audioOutput, or \c nil if audio is not enabled
/// in the preset.
@property (readonly, nonatomic, nullable) AVCaptureConnection *audioConnection;

/// Delegate to receive video \c CMSampleBuffers.
@property (weak, nonatomic, nullable)
    id<AVCaptureVideoDataOutputSampleBufferDelegate> videoDelegate;

/// Delegate to receive audio \c CMSampleBuffers.
@property (weak, nonatomic, nullable)
    id<AVCaptureAudioDataOutputSampleBufferDelegate> audioDelegate;

@end

@interface CAMHardwareSessionFactory : NSObject

/// Creates a session according to the given \c preset. This includes creating and attaching video
/// input and output, still output, and according to the preset, may also include audio input and
/// output.
///
/// Returned signal sends the created \c CAMHardwareSession and completes, or sends an appropriate
/// error if an error occurred at any stage. All events are sent on an arbitrary thread.
+ (RACSignal *)sessionWithPreset:(CAMDevicePreset *)preset;

@end

NS_ASSUME_NONNULL_END
