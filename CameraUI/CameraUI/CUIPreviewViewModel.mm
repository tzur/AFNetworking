// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIPreviewViewModel.h"

#import <Camera/CAMExposureDevice.h>
#import <Camera/CAMFocusDevice.h>
#import <Camera/CAMPreviewLayerDevice.h>
#import <Camera/CAMVideoDevice.h>
#import <Camera/CAMZoomDevice.h>

#import "CUIFocusIconMode.h"
#import "RACSignal+CameraUI.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIPreviewViewModel ()

/// Camera device model.
@property (readonly, nonatomic) id<CAMExposureDevice, CAMFocusDevice, CAMPreviewLayerDevice,
    CAMVideoDevice, CAMZoomDevice> cameraDevice;

/// \c YES when pinch-to-zoom gesture should be enabled.
@property (readwrite, nonatomic) BOOL pinchEnabled;

/// Subject for sending \c CUIFocusIconMode marking how and where the focus icon should be shown.
@property (readonly, nonatomic) RACSubject *focusModeSubject;

@end

@implementation CUIPreviewViewModel

static const CGFloat kMaxZoom = 4.0;

- (instancetype)initWithDevice:(id<CAMExposureDevice, CAMFocusDevice, CAMPreviewLayerDevice,
    CAMVideoDevice, CAMZoomDevice>)cameraDevice {
  if (self = [super init]) {
    _cameraDevice = cameraDevice;
    [self setupCameraProperties];
    [self setupPreview];
    [self setupFocus];
  }
  return self;
}

- (void)setupCameraProperties {
  _tapEnabled = YES;
  RAC(self, pinchEnabled) = RACObserve(self, cameraDevice.hasZoom);
}

- (void)setupPreview {
  _previewLayer = self.cameraDevice.previewLayer;
  self.gridHidden = YES;
}

#pragma mark -
#pragma mark Zoom
#pragma mark -

- (void)previewPinched:(UIPinchGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    return;
  }
  [self zoomByFactor:gestureRecognizer.scale];
  gestureRecognizer.scale = 1;
}

- (void)zoomByFactor:(CGFloat)factor {
  CGFloat newZoom = self.cameraDevice.zoomFactor * factor;
  CGFloat maxZoom = std::min(kMaxZoom, self.cameraDevice.maxZoomFactor);
  CGFloat finalZoom = std::clamp(newZoom, self.cameraDevice.minZoomFactor, maxZoom);
  [self activateSignal:[self.cameraDevice setZoom:finalZoom]];
}

#pragma mark -
#pragma mark Focus
#pragma mark -

- (void)setupFocus {
  _focusModeSubject = [[RACSubject alloc] init];
  [self setupSubjectAreaChangedSignal];
  _focusModeAndPosition = [self.focusModeSubject distinctUntilChanged];
}

- (void)setupSubjectAreaChangedSignal {
  @weakify(self);
  [self.cameraDevice.subjectAreaChanged
      subscribeNext:^(id) {
        @strongify(self);
        CGPoint devicePoint = CGPointMake(0.5, 0.5);
        [self activateSignal:[self.cameraDevice setContinuousFocusPoint:devicePoint]];
        [self activateSignal:[self.cameraDevice setContinuousExposurePoint:devicePoint]];
        CGPoint viewPoint = [self.cameraDevice previewLayerPointFromDevicePoint:devicePoint];
        [self.focusModeSubject sendNext:[CUIFocusIconMode indefiniteFocusAtPosition:viewPoint]];
      }];
}

- (void)previewTapped:(UITapGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    return;
  }
  CGPoint viewPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
  [self.focusModeSubject sendNext:[CUIFocusIconMode definiteFocusAtPosition:viewPoint]];

  CGPoint devicePoint = [self.cameraDevice devicePointFromPreviewLayerPoint:viewPoint];
  RACSignal *setFocus = [self.cameraDevice setSingleFocusPoint:devicePoint];
  RACSignal *setExposure = [self.cameraDevice setSingleExposurePoint:devicePoint];
  @weakify(self);
  [[RACSignal zip:@[setFocus, setExposure]] subscribeNext:^(id) {
    @strongify(self);
    [self.focusModeSubject sendNext:[CUIFocusIconMode hiddenFocus]];
  }];
}

#pragma mark -
#pragma mark Utils
#pragma mark -

- (void)activateSignal:(RACSignal *)signal {
  [[signal
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(id) {}];
}

@end

NS_ASSUME_NONNULL_END
