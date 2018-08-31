// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of torch control.
@protocol CAMTorchDevice <NSObject>

/// Sets the camera's torch to the given illumination level. \c torchLevel should be in the range
/// <tt>[0, 1]</tt>. A value of \c 0 turns off the torch.
///
/// Returned signal sends the new \c torchLevel and completes when the new level is set, or errs if
/// there is a problem setting the torch level. All events are sent on an arbitrary thread.
- (RACSignal *)setTorchLevel:(float)torchLevel;

/// Sets the camera's torch to the given torch mode.
///
/// Returned signal sends the new \c torchMode and completes when the new mode is set, or errs if
/// there is a problem setting the torch mode. All events are sent on an arbitrary thread.
- (RACSignal *)setTorchMode:(AVCaptureTorchMode)torchMode;

/// Whether the camera has a torch.
@property (readonly, nonatomic) BOOL hasTorch;

@end

NS_ASSUME_NONNULL_END
