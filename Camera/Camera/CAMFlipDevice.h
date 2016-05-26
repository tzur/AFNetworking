// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

@class CAMDeviceCamera;

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of changing the physical device used for capturing video.
@protocol CAMFlipDevice <NSObject>

/// Changes the physical camera device to the given one.
///
/// Returned signal sends the new \c camera and completes when the new physical camera is set, or
/// errs if there is a problem setting the camera. All events are sent on an arbitrary thread.
- (RACSignal *)setCamera:(CAMDeviceCamera *)camera;

/// Currently active physical camera device.
@property (readonly, nonatomic) CAMDeviceCamera *activeCamera;

/// Whether or not there are more physical camera devices available.
@property (readonly, nonatomic) BOOL canChangeCamera;

@end

NS_ASSUME_NONNULL_END
