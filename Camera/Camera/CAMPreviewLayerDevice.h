// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of providing live preview through a \c CALayer.
@protocol CAMPreviewLayerDevice <NSObject>

/// Converts the given point in device coordinates to \c previewLayer's coordinates.
- (CGPoint)previewLayerPointFromDevicePoint:(CGPoint)devicePoint;

/// Converts the given point in \c previewLayer's coordinates to device coordinates.
- (CGPoint)devicePointFromPreviewLayerPoint:(CGPoint)previewLayerPoint;

/// Layer that displays an unedited live preview from the camera.
@property (readonly, nonatomic) CALayer *previewLayer;

/// Current interface orientation. Setting this property to the current orientation of the
/// interface will result in correctly oriented preview in \c previewLayer.
///
/// @see UIApplication.statusBarOrientation.
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

@end

NS_ASSUME_NONNULL_END
