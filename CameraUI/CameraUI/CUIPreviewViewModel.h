// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIGridViewModel.h"

#import <Camera/CAMExposureDevice.h>
#import <Camera/CAMFocusDevice.h>
#import <Camera/CAMPreviewLayerDevice.h>
#import <Camera/CAMVideoDevice.h>
#import <Camera/CAMZoomDevice.h>

NS_ASSUME_NONNULL_BEGIN

/// Camera device suitable for \c CUIPreviewViewModel.
@protocol CUIPreviewDevice <CAMExposureDevice, CAMFocusDevice, CAMPreviewLayerDevice,
    CAMVideoDevice, CAMZoomDevice>
@end

/// ViewModel for CUIPreviewViewController. Provides a live preview, controls focus and zoom.
@interface CUIPreviewViewModel : NSObject <CUIGridContainer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device.
- (instancetype)initWithDevice:(id<CUIPreviewDevice>)device NS_DESIGNATED_INITIALIZER;

/// Called by the view controller when the preview view was tapped.
- (void)previewTapped:(UITapGestureRecognizer *)gestureRecognizer;

/// Called by the view controller when the preview view was pinched.
- (void)previewPinched:(UIPinchGestureRecognizer *)gestureRecognizer;

/// Activate capture animation.
- (void)performCaptureAnimation;

/// Preview layer.
@property (readonly, nonatomic) CALayer *previewLayer;

/// Hot signal that sends \c RACUnits whenever the "capturing" animation should be performed.
@property (readonly, nonatomic) RACSignal *animateCapture;

/// Hot signal that sends \c CUIFocusIconMode marking how and where the focus icon should be shown.
@property (readonly, nonatomic) RACSignal *focusModeAndPosition;

/// \c YES when the device supports focus and tap-to-focus gesture should be enabled.
@property (readonly, nonatomic) BOOL tapEnabled;

/// \c YES when the device supports zoom and pinch-to-zoom gesture should be enabled.
@property (readonly, nonatomic) BOOL pinchEnabled;

@end

NS_ASSUME_NONNULL_END
