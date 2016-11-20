// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIPreviewViewModel.h"

#import "CUIFocusIconMode.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIPreviewViewModel ()

/// Camera device model.
@property (readonly, nonatomic) id<CUIPreviewDevice> device;

/// \c YES when pinch-to-zoom gesture should be enabled.
@property (readwrite, nonatomic) BOOL pinchEnabled;

/// Subject for sending \c CUIFocusIconMode marking how and where the focus icon should be shown.
@property (readonly, nonatomic) RACSubject *focusModeSubject;

/// \c YES when \c previewLayer should be used for the live preview, else \c previewSignal should
/// be used for the live preview.
@property (readwrite, nonatomic) BOOL usePreviewLayer;

@end

@implementation CUIPreviewViewModel

@synthesize usePreviewLayer = _usePreviewLayer;
@synthesize previewLayer = _previewLayer;
@synthesize previewSignal = _previewSignal;
@synthesize animateCapture = _animateCapture;
@synthesize focusModeAndPosition = _focusModeAndPosition;
@synthesize tapEnabled = _tapEnabled;
@synthesize pinchEnabled = _pinchEnabled;
@synthesize gridHidden = _gridHidden;

static const CGFloat kMaxZoom = 4.0;

- (instancetype)initWithDevice:(id<CUIPreviewDevice>)device
                 previewSignal:(RACSignal *)previewSignal
         usePreviewLayerSignal:(RACSignal *)usePreviewLayerSignal {
  if (self = [super init]) {
    _device = device;
    _previewLayer = device.previewLayer;
    _previewSignal = previewSignal;
    RAC(self, usePreviewLayer) = usePreviewLayerSignal;
    [self setupZoom];
    [self setupFocus];
    [self setupCaptureAnimation];
    _gridHidden = YES;
  }
  return self;
}

- (void)setupZoom {
  RAC(self, pinchEnabled, @NO) = RACObserve(self, device.hasZoom);
}

- (void)setupFocus {
  _tapEnabled = YES;

  _focusModeSubject = [[RACSubject alloc] init];

  _focusModeAndPosition = [[[self.focusModeSubject
      distinctUntilChanged]
      filter:^BOOL(CUIFocusIconMode *focusIconAction) {
        if (focusIconAction.mode == CUIFocusIconDisplayModeHidden) {
          return YES;
        }
        CGPoint point = [focusIconAction.position CGPointValue];
        return std::isfinite(point.x) && std::isfinite(point.y);
      }]
      takeUntil:[self rac_willDeallocSignal]];

  [self setupSubjectAreaChangedSignal];
}

- (void)setupCaptureAnimation {
  _animateCapture = [[self rac_signalForSelector:@selector(performCaptureAnimation)]
      mapReplace:[RACUnit defaultUnit]];
}

- (void)performCaptureAnimation {
  // Handled with rac_signalForSelector.
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
  CGFloat newZoom = self.device.zoomFactor * factor;
  CGFloat maxZoom = std::min(kMaxZoom, self.device.maxZoomFactor);
  CGFloat finalZoom = std::clamp(newZoom, self.device.minZoomFactor, maxZoom);
  [self activateSignal:[self.device setZoom:finalZoom]];
}

#pragma mark -
#pragma mark Focus
#pragma mark -

- (void)setupSubjectAreaChangedSignal {
  @weakify(self);
  [[self.device.subjectAreaChanged
      takeUntil:[self rac_willDeallocSignal]]
      subscribeNext:^(id) {
        @strongify(self);
        CGPoint devicePoint = CGPointMake(0.5, 0.5);
        [self activateSignal:[self.device setContinuousFocusPoint:devicePoint]];
        [self activateSignal:[self.device setContinuousExposurePoint:devicePoint]];
        CGPoint viewPoint = [self.device previewLayerPointFromDevicePoint:devicePoint];
        [self.focusModeSubject sendNext:[CUIFocusIconMode indefiniteFocusAtPosition:viewPoint]];
      }];
}

- (void)previewTapped:(UITapGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateFailed) {
    return;
  }
  CGPoint viewPoint = [gestureRecognizer locationInView:gestureRecognizer.view];
  [self.focusModeSubject sendNext:[CUIFocusIconMode definiteFocusAtPosition:viewPoint]];

  CGPoint devicePoint = [self.device devicePointFromPreviewLayerPoint:viewPoint];
  RACSignal *setFocus = [self.device setSingleFocusPoint:devicePoint];
  RACSignal *setExposure = [self.device setSingleExposurePoint:devicePoint];
  @weakify(self);
  [[[RACSignal
      zip:@[
        [setFocus catchTo:[RACSignal empty]],
        [setExposure catchTo:[RACSignal empty]]
      ]]
      takeUntil:[self rac_willDeallocSignal]]
      subscribeCompleted:^{
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
