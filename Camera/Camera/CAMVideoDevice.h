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

/// Sets the pixel format of the frames sent on \c videoFrames.
///
/// Returned signal sends the new \c pixelFormat and completes when the new format is set, or errs
/// if there is a problem setting the format. All events are sent on an arbitrary thread.
///
/// @see CAMVideoFrame.
- (RACSignal *)setPixelFormat:(CAMPixelFormat *)pixelFormat;

/// Maps any value from \c trigger to a \c UIImage captured as quickly as possible. This is needed
/// for features that require hardware-level synchronization, such as flash (see \c CAMFlashDevice).
///
/// Returned signal completes when the receiver is deallocated or \c trigger completes, or errs
/// if there is a problem capturing an image. All events are sent on an arbitrary thread.
- (RACSignal *)stillFramesWithTrigger:(RACSignal *)trigger;

/// Signal that sends \c CAMVideoFrames captured by the camera. The signal completes when the
/// receiver is deallocated or errs if there is a problem capturing video. All events are sent on
/// an arbitrary thread.
@property (readonly, nonatomic) RACSignal *videoFrames;

/// Video orientation. The current value of this property is embedded into every video frame on
/// \c videoFrames and \c stillFramesWithTrigger:. Setting this to the current orientation of the
/// device will result in correctly oriented images.
@property (nonatomic) AVCaptureVideoOrientation videoOrientation;

/// Signal that sends \c RACUnit whenever the subject in front of the camera has changed
/// significantly, and completes when the receiver is deallocated, or errs if there is a problem
/// detecting changes. All events are sent on an arbitrary thread.
///
/// @see AVCaptureDevice.subjectAreaChangeMonitoringEnabled
@property (readonly, nonatomic) RACSignal *subjectAreaChanged;

@end

NS_ASSUME_NONNULL_END
