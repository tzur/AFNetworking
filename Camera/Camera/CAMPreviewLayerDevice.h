// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of providing live preview through a \c CALayer.
@protocol CAMPreviewLayerDevice <NSObject>

/// Converts the given point in device coordinates to \c previewLayer's coordinates.
- (CGPoint)previewLayerPointFromDevicePoint:(CGPoint)devicePoint;

/// Converts the given point in \c previewLayer's coordinates to device coordinates.
- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint;

/// Layer that displays an unedited live preview from the camera. The preview is oriented to fit in
/// portrait display.
@property (readonly, nonatomic) CALayer *previewLayer;

/// \c YES if the live preview should have portrait orientation regardless to the
/// device's orientation, and \c NO if the live preview should be rotated to match device
/// orientation. When the preview view that shows the live preview is locked on portrait
/// orientation, setting the value to \c YES will result in live preview that matches the preview
//// orientation.
@property (nonatomic) BOOL previewLayerWithPortraitOrientation;

/// Device orientation. When \c previewLayerWithPortraitOrientation is \c NO, setting this property
/// to the current orientation of the device will result in preview that matches the device's
/// orientation.
@property (nonatomic) UIInterfaceOrientation deviceOrientation;

@end

NS_ASSUME_NONNULL_END
