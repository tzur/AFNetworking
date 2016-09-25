// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

@class CAMPixelFormat;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of sending a stream of video frames.
///
/// Video frames can be read continuously using \c videoFrames or on-demand using
/// \c stillFramesWithTrigger:.
@protocol CAMVideoDevice <NSObject>

/// Sets the pixel format of the frames sent on \c videoFrames and \c stillFramesWithTrigger:.
///
/// Returned signal sends the new \c pixelFormat and completes when the new format is set, or errs
/// if there is a problem setting the format. All events are sent on an arbitrary thread.
///
/// @see CAMVideoFrame.
- (RACSignal *)setPixelFormat:(CAMPixelFormat *)pixelFormat;

/// Maps any value from \c trigger to a \c CAMVideoFrame captured as quickly as possible. This is
/// needed for features that require hardware-level synchronization, such as flash (see \c
/// CAMFlashDevice). The captured image orientation is set according to \c gravityOrientation.
///
/// Returned signal completes when the receiver is deallocated or \c trigger completes, or errs
/// if there is a problem capturing an image. All events are sent on an arbitrary thread.
- (RACSignal *)stillFramesWithTrigger:(RACSignal *)trigger;

/// Signal that sends \c CAMVideoFrames captured by the camera.
///
/// The frames are oriented according to \c interfaceOrientation. Frames from the front camera are
/// mirrored before being sent over the signal.
///
/// The signal completes when the receiver is deallocated or errs if there is a problem capturing
/// video. All events are sent on an arbitrary thread.
@property (readonly, nonatomic) RACSignal *videoFrames;

/// Current interface orientation. Setting this property to the current orientation of the
/// interface will result in correctly oriented frames sent over \c videoFrames.
///
/// @see UIApplication.statusBarOrientation.
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

/// Current orientation of the gravity. Setting this property to the current orientation of the
/// gravity will result in correctly oriented frames sent over \c stillFramesWithTrigger:.
///
/// In most cases this is the same as \c interfaceOrientation, except when the device orientation
/// lock is activated (either by the user or by an app).
///
/// @see CAMDeviceOrientation.
@property (nonatomic) UIInterfaceOrientation gravityOrientation;

/// Signal that sends \c RACUnit whenever the subject in front of the camera has changed
/// significantly, and completes when the receiver is deallocated, or errs if there is a problem
/// detecting changes. All events are sent on an arbitrary thread.
///
/// @see AVCaptureDevice.subjectAreaChangeMonitoringEnabled
@property (readonly, nonatomic) RACSignal *subjectAreaChanged;

@end

NS_ASSUME_NONNULL_END
