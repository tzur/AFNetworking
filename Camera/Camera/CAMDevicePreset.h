// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

@protocol CAMFormatStrategy;

NS_ASSUME_NONNULL_BEGIN

/// Valid pixel formats for a \c CAMDevice.
LTEnumDeclare(NSUInteger, CAMPixelFormat,
  /// 32-bit BGRA, equivalent to \c kCVPixelFormatType_32BGRA.
  ///
  /// @see kCVPixelFormatType_32BGRA.
  CAMPixelFormatBGRA,
  /// Y'CbCr 4:2:0 full-range, equivalent to \c kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
  ///
  /// @see kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
  CAMPixelFormat420f
);

/// Category for adding utility methods for \c CAMPixelFormat.
@interface CAMPixelFormat (Utility)

/// Returns the pixel format in the corresponding system format.
- (OSType)cvPixelFormat;

/// Returns a video settings dictionary in the format expected by \c AVCaptureVideoDataOutput,
/// which sets the receiver as the pixel format.
- (NSDictionary *)videoSettings;

@end

/// Physical camera devices controlled by \c CAMDevice.
LTEnumDeclare(NSUInteger, CAMDeviceCamera,
  /// Front camera.
  CAMDeviceCameraFront,
  /// Back camera.
  CAMDeviceCameraBack
);

/// Category for adding utility methods for \c CAMDeviceCamera.
@interface CAMDeviceCamera (Utility)

/// Returns a \c AVCaptureDevice matching the receiver, or \c nil if none is found. In case more
/// than one matches, an arbitrary one is returned.
- (nullable AVCaptureDevice *)device;

/// Returns a \c AVCaptureDevicePosition matching the receiver. May return
/// \c AVCaptureDevicePositionUnspecified if no better match is found.
- (AVCaptureDevicePosition)position;

@end

/// Value class describing initial configuration of a \c CAMDevice.
@interface CAMDevicePreset : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given values.
- (instancetype)initWithPixelFormat:(CAMPixelFormat *)pixelFormat camera:(CAMDeviceCamera *)camera
    enableAudio:(BOOL)enableAudio automaticallyConfiguresApplicationAudioSession:
    (BOOL)automaticallyConfiguresApplicationAudioSession
    formatStrategy:(id<CAMFormatStrategy>)formatStrategy outputQueue:(dispatch_queue_t)outputQueue
    NS_DESIGNATED_INITIALIZER;

/// Initializes with the given values and \c automaticallyConfiguresApplicationAudioSession set to
/// \c YES.
- (instancetype)initWithPixelFormat:(CAMPixelFormat *)pixelFormat camera:(CAMDeviceCamera *)camera
                        enableAudio:(BOOL)enableAudio
                     formatStrategy:(id<CAMFormatStrategy>)formatStrategy
                        outputQueue:(dispatch_queue_t)outputQueue;

/// Pixel format of the video frames delivered by the camera.
@property (readonly, nonatomic) CAMPixelFormat *pixelFormat;

/// Physical camera device to capture from.
@property (readonly, nonatomic) CAMDeviceCamera *camera;

/// If \c YES, audio will be captured in addition to video.
///
/// @note There's a limitation in iOS that causes audio not to be captured for some video formats.
/// When enabling audio, a suitable \c formatStrategy should be selected.
@property (readonly, nonatomic) BOOL enableAudio;

/// If \c YES the capture session will automatically configure the app’s shared AVAudioSession
/// instance for optimal recording.
///
/// @see AVCaptureSession.automaticallyConfiguresApplicationAudioSession.
@property (readonly, nonatomic) BOOL automaticallyConfiguresApplicationAudioSession;

/// Strategy to select a \c AVCaptureDeviceFormat to use for capturing video, out of the available
/// formats for the current physical \c camera.
///
/// @see AVCaptureDevice.formats.
///
/// @note There's a limitation in iOS that causes audio not to be captured for some video formats.
/// When enabling audio, a suitable \c formatStrategy should be selected.
@property (readonly, nonatomic) id<CAMFormatStrategy> formatStrategy;

/// Dispatch queue to create \c LTTexture objects on. This queue must run on a thread with valid
/// OpenGL context.
@property (readonly, nonatomic) dispatch_queue_t outputQueue;

@end

NS_ASSUME_NONNULL_END
