// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of flashing while taking images.
@protocol CAMFlashDevice <NSObject>

/// Sets the camera's flash mode. Note that to produce flash-lit images, you need to use
/// \c stillFramesWithTrigger (see \c CAMVideoDevice).
///
/// Returned signal sends the new \c flashMode and completes when the new mode is set, or errs if
/// there is a problem setting the flash mode. All events are sent on an arbitrary thread.
- (RACSignal *)setFlashMode:(AVCaptureFlashMode)flashMode;

/// Whether the camera is capable of flashing.
@property (readonly, nonatomic) BOOL hasFlash;

/// Whether the camera's flash will light if an image is captured right now. When the current flash
/// mode is \c AVCaptureFlashModeAuto, this depends on current exposure measurements.
@property (readonly, nonatomic) BOOL flashWillFire;

/// Currently active flash mode.
@property (readonly, nonatomic) AVCaptureFlashMode currentFlashMode;

@end

NS_ASSUME_NONNULL_END
