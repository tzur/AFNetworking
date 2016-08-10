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
///
/// Live preview is provided via a signal of \c LTTextures (\c previewSignal), or via
/// a layer (\c previewLayer) when the signal is \c nil.
@protocol CUIPreviewViewModel <CUIGridContainer>

/// Called by the view controller when the preview view was tapped.
- (void)previewTapped:(UITapGestureRecognizer *)gestureRecognizer;

/// Called by the view controller when the preview view was pinched.
- (void)previewPinched:(UIPinchGestureRecognizer *)gestureRecognizer;

/// Activate capture animation.
- (void)performCaptureAnimation;

/// \c YES when \c previewLayer should be used for the live preview, else \c previewSignal should
/// be used for the live preview.
@property (readonly, nonatomic) BOOL usePreviewLayer;

/// Layer showing live preview from the camera.
///
/// This property is guaranteed to not change after initialization and so does not need to be
/// observed.
@property (readonly, nonatomic) CALayer *previewLayer;

/// Signal of \c LTTextures, showing live preview from the camera.
///
/// This property is guaranteed to not change after initialization and so does not need to be
/// observed.
@property (readonly, nonatomic) RACSignal *previewSignal;

/// Hot signal that sends \c RACUnits whenever the "capturing" animation should be performed.
@property (readonly, nonatomic) RACSignal *animateCapture;

/// Hot signal that sends \c CUIFocusIconMode marking how and where the focus icon should be shown.
@property (readonly, nonatomic) RACSignal *focusModeAndPosition;

/// \c YES when the device supports focus and tap-to-focus gesture should be enabled.
@property (readonly, nonatomic) BOOL tapEnabled;

/// \c YES when the device supports zoom and pinch-to-zoom gesture should be enabled.
@property (readonly, nonatomic) BOOL pinchEnabled;

@end

/// Concrete implementation of \c id<CUIPreviewViewModel>.
///
/// The pinch-to-zoom gesture is always enabled, and tap-to-focus is enabled when the device is
/// capable of focusing.
@interface CUIPreviewViewModel : NSObject <CUIPreviewViewModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c device and live preview signal. When \c usePreviewLayerSignal
/// sends \c YES, the device layer is used as the preview instead of the \c previewSignal.
- (instancetype)initWithDevice:(id<CUIPreviewDevice>)device
                 previewSignal:(RACSignal *)previewSignal
         usePreviewLayerSignal:(RACSignal *)usePreviewLayerSignal NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
