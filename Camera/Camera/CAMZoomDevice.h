// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for a camera device capable of changing the zoom level.
@protocol CAMZoomDevice <NSObject>

/// Sets the camera's zoom factor to the given value as fast as possible. The given \c zoomFactor
/// will be clamped to <tt>[minZoomFactor, maxZoomFactor]</tt>.
///
/// Returned signal sends the new \c zoomFactor and completes when the new zoom factor is set, or
/// errs if there is a problem setting the zoom factor. All events are sent on an arbitrary thread.
- (RACSignal *)setZoom:(CGFloat)zoomFactor;

/// Sets the camera's zoom factor to the given value at the given rate. Zoom factor will change at
/// an exponential rate, with a \c rate of \c 1 meaning it will double/halve every second. The
/// given \c zoomFactor will be clamped to <tt>[minZoomFactor, maxZoomFactor]</tt>.
///
/// Returned signal sends the new \c zoomFactor and completes when the new zoom factor is set, or
/// errs if there is a problem setting the zoom factor. All events are sent on an arbitrary thread.
- (RACSignal *)setZoom:(CGFloat)zoomFactor rate:(float)rate;

/// Whether the camera is capable of zooming.
@property (readonly, nonatomic) BOOL hasZoom;

/// Minimum zoom factor supported by the camera.
@property (readonly, nonatomic) CGFloat minZoomFactor;

/// Maximum zoom factor supported by the camera.
@property (readonly, nonatomic) CGFloat maxZoomFactor;

/// Current zoom factor of the camera.
@property (readonly, nonatomic) CGFloat zoomFactor;

@end

NS_ASSUME_NONNULL_END
