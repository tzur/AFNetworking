// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of providing live preview through a \c CALayer.
@protocol CAMPreviewLayerDevice <NSObject>

/// Converts the given point in device coordinates to \c previewLayer's coordinates.
///
/// Returned signal sends the converted \c CGPoint and completes, or errs if there is a problem
/// converting. All events are sent on an arbitrary thread.
- (RACSignal *)previewLayerPointFromDevicePoint:(CGPoint)devicePoint;

/// Converts the given point in \c previewLayer's coordinates to device coordinates.
///
/// Returned signal sends the converted \c CGPoint and completes, or errs if there is a problem
/// converting. All events are sent on an arbitrary thread.
- (RACSignal *)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint;

/// Layer that displays an unedited live preview from the camera.
///
/// Returned signal sends a \c CALayer and completes, or errs if there is a problem getting the
/// layer. All events are sent on an arbitrary thread.
- (RACSignal *)previewLayer;

@end

NS_ASSUME_NONNULL_END
