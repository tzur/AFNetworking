// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

@class CAMDeviceCamera, CAMPixelFormat;

@protocol CAMFormatStrategy;

NS_ASSUME_NONNULL_BEGIN

/// Thin wrapper around a \c AVCaptureSession object, with methods for assisting in initializing
/// it and accessing its properties.
///
/// All methods operate synchronously on the current queue. It's the caller's responsibility to
/// make sure the main queue is not blocked.
///
/// Still image output is represented either by \c stillOutput property (iOS 9 and before) or by
/// \c photoOutput property (iOS 10 and after). The distinction is done because the
/// \c AVCapturePhotoOutput class (the class of \c photoOutput property) has been introduced in iOS
/// 10.
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

/// Still output attached to this session. Guaranteed to be non-null for iOS 9 and before.
@property (readonly, nonatomic, nullable) AVCaptureStillImageOutput *stillOutput
    NS_DEPRECATED_IOS(4_0, 10_0, "Use photoOutput instead");

/// Still output attached to this session. Guaranteed to be non-null for iOS 10 and after.
@property (readonly, nonatomic, nullable) AVCapturePhotoOutput *photoOutput
    API_AVAILABLE(ios(10.0));

/// Pixel format to use for a single photo capture request when running on iOS 10 and up.
@property (strong, nonatomic, nullable) CAMPixelFormat *pixelFormat;

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

NS_ASSUME_NONNULL_END
