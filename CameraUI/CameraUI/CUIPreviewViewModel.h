// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

@protocol CAMExposureDevice, CAMFocusDevice, CAMPreviewLayerDevice, CAMVideoDevice, CAMZoomDevice;

NS_ASSUME_NONNULL_BEGIN

/// ViewModel for CUIPreviewViewController. Provides a live preview, controls focus and zoom.
@interface CUIPreviewViewModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the preview view model with the given camera device.
- (instancetype)initWithDevice:(id<CAMExposureDevice, CAMFocusDevice, CAMPreviewLayerDevice,
    CAMVideoDevice, CAMZoomDevice>)cameraDevice NS_DESIGNATED_INITIALIZER;

/// Called by the view controller when the preview view was tapped.
- (void)previewTapped:(UITapGestureRecognizer *)gestureRecognizer;

/// Called by the view controller when the preview view was pinched.
- (void)previewPinched:(UIPinchGestureRecognizer *)gestureRecognizer;

/// Preview layer.
@property (readonly, nonatomic) CALayer *previewLayer;

/// Signal that sends \c CUIFocusIconMode marking how and where the focus icon should be shown.
@property (readonly, nonatomic) RACSignal *focusModeAndPosition;

/// \c YES when the device supports focus and tap-to-focus gesture should be enabled.
@property (readonly, nonatomic) BOOL tapEnabled;

/// \c YES when the device supports zoom and pinch-to-zoom gesture should be enabled.
@property (readonly, nonatomic) BOOL pinchEnabled;

/// \c YES when the grid overlay view should be hidden. Defaults to \c YES.
@property (nonatomic) BOOL gridHidden;

@end

NS_ASSUME_NONNULL_END
