// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIPreviewViewController.h"

#import "CUIFocusIconMode.h"
#import "CUIFocusView.h"
#import "CUIGridView.h"
#import "CUILayerView.h"
#import "CUIPreviewViewModel.h"
#import "CUISampleBufferView.h"
#import "CUISharedTheme.h"
#import "UIViewController+LifecycleSignals.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIPreviewViewController ()

/// View model to determine the properties displayed by this view controller.
@property (readonly, nonatomic) id<CUIPreviewViewModel> viewModel;

/// View for attaching gesture recognizers.
@property (readonly, nonatomic) UIView *gestureView;

/// View showing the preview image of \c previewLayer.
@property (readonly, nonatomic) UIView *previewView;

/// View showing the preview image of \c previewSignal.
@property (readonly, nonatomic) UIView *previewFromSignalView;

/// View used for blurring the \c previewView.
@property (readonly, nonatomic) UIVisualEffectView *blurView;

/// Focus indicator.
@property (readonly, nonatomic) CUIFocusView *focusView;

/// Grid overlay.
@property (readonly, nonatomic) CUIGridView *gridView;

/// Recognizer for tap gestures, used to control the camera focus.
@property (readonly, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

/// Recognizer for pinch gestures, used to control the camera zoom.
@property (readonly, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

@end

@implementation CUIPreviewViewController

- (instancetype)initWithViewModel:(id<CUIPreviewViewModel>)viewModel {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _viewModel = viewModel;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.accessibilityIdentifier = @"CameraPreview";
  [self setupPreviewView];
  [self setupGestureView];
  [self setupBlurView];
  [self setupFocusView];
  [self setupGridView];
  [self setupCaptureAnimation];
}

#pragma mark -
#pragma mark Gestures
#pragma mark -

- (void)setupGestureView {
  _gestureView = [[UIView alloc] initWithFrame:CGRectZero];

  [self.view addSubview:self.gestureView];
  [self.gestureView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];

  _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.viewModel
                                                                  action:@selector(previewTapped:)];
  [self.gestureView addGestureRecognizer:self.tapGestureRecognizer];
  RAC(self.tapGestureRecognizer, enabled, @NO) = RACObserve(self, viewModel.tapEnabled);

  _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
      initWithTarget:self.viewModel action:@selector(previewPinched:)];
  [self.gestureView addGestureRecognizer:self.pinchGestureRecognizer];
  RAC(self.pinchGestureRecognizer, enabled, @NO) = RACObserve(self, viewModel.pinchEnabled);
}

#pragma mark -
#pragma mark Preview
#pragma mark -

- (void)setupPreviewView {
  [self setupPreviewLayerView];
  [self setupPreviewSignalView];
}

- (void)setupPreviewLayerView {
  _previewView = [[CUILayerView alloc] initWithLayer:self.viewModel.previewLayer];
  self.previewView.accessibilityIdentifier = @"LayerView";
  RAC(self.previewView, hidden) = [RACObserve(self.viewModel, usePreviewLayer) not];
  [self.view addSubview:self.previewView];
  [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

- (void)setupPreviewSignalView {
  RACSignal *frames = [RACSignal if:[self cui_isVisible]
                               then:self.viewModel.previewSignal
                               else:[RACSignal never]];

  CUISampleBufferView *signalView = [[CUISampleBufferView alloc] initWithVideoFrames:frames];
  signalView.accessibilityIdentifier = @"SignalView";
  _previewFromSignalView = signalView;

  RAC(self.previewFromSignalView, hidden) = RACObserve(self.viewModel, usePreviewLayer);
  [self.view addSubview:self.previewFromSignalView];
  [self.previewFromSignalView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

#pragma mark -
#pragma mark Grid
#pragma mark -

- (void)setupGridView {
  _gridView = [CUIGridView whiteGrid];

  RAC(self.gridView, hidden, @YES) = RACObserve(self, viewModel.gridHidden);

  [self.view addSubview:self.gridView];
  [self.gridView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

#pragma mark -
#pragma mark Focus
#pragma mark -

- (void)setupFocusView {
  static const CGFloat kFocusSquareSize = 65;
  static const CGFloat kFocusPlusSize = 20;
  static const CGFloat kFocusLineWidth = 1;
  static const CGFloat kFocusOutlineWidth = 0.5;
  static const CGFloat kFocusEdgeLength = kFocusSquareSize + 2 * kFocusOutlineWidth;

  _focusView =
      [[CUIFocusView alloc] initWithFrame:CGRectFromSize(CGSizeMakeUniform(kFocusEdgeLength))];
  self.focusView.plusLength = kFocusPlusSize;
  self.focusView.lineWidth = kFocusLineWidth;
  self.focusView.outlineWidth = kFocusOutlineWidth;
  self.focusView.color = [UIColor whiteColor];
  self.focusView.outlineColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
  self.focusView.alpha = 0;
  self.focusView.userInteractionEnabled = NO;

  [self.view addSubview:self.focusView];

  @weakify(self);
  [self.viewModel.focusModeAndPosition subscribeNext:^(CUIFocusIconMode *focusIconAction) {
    @strongify(self);
    switch (focusIconAction.mode) {
      case CUIFocusIconDisplayModeDefinite:
        [self showFocusIconAt:[focusIconAction.position CGPointValue]];
        break;
      case CUIFocusIconDisplayModeHidden:
        [self hideFocusIcon];
        break;
      case CUIFocusIconDisplayModeIndefinite:
        [self showIndefiniteFocusIconAt:[focusIconAction.position CGPointValue]];
        break;
    }
  }];
}

- (void)showFocusIconAt:(CGPoint)position {
  [self.focusView.layer removeAllAnimations];

  self.focusView.color = [UIColor whiteColor];
  self.focusView.center = position;
  self.focusView.alpha = 0;
  self.focusView.transform = CGAffineTransformMakeScale(1.5, 1.5);

  [UIView animateWithDuration:0.15 animations:^{
    static const UIViewAnimationOptions kEaseInOutOptions =
        UIViewAnimationOptionOverrideInheritedCurve | UIViewAnimationOptionCurveEaseInOut;
    [UIView animateWithDuration:0 delay:0 options:kEaseInOutOptions animations:^{
      self.focusView.transform = CGAffineTransformIdentity;
    } completion:nil];
    self.focusView.alpha = 1;
  }];
}

- (void)hideFocusIcon {
  [self.focusView.layer removeAllAnimations];

  self.focusView.color = [CUISharedTheme sharedTheme].iconHighlightedColor;

  [UIView animateWithDuration:0.3 delay:0.5 options:0 animations:^{
    self.focusView.alpha = 0;
  } completion:nil];
}

- (void)showIndefiniteFocusIconAt:(CGPoint)position {
  [self.focusView.layer removeAllAnimations];

  self.focusView.color = [UIColor whiteColor];
  self.focusView.center = position;
  self.focusView.alpha = 0;
  self.focusView.transform = CGAffineTransformMakeScale(1.5, 1.5);

  [UIView animateKeyframesWithDuration:1.5 delay:0 options:0 animations:^{
    [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.15 animations:^{
      self.focusView.alpha = 1;
    }];
    [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^{
      self.focusView.alpha = 0;
    }];
  } completion:nil];
}

#pragma mark -
#pragma mark Blur
#pragma mark -

- (void)setupBlurView {
  UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
  _blurView = [[UIVisualEffectView alloc] initWithEffect:effect];

  self.blurView.userInteractionEnabled = NO;
  RAC(self.blurView, hidden) = [[RACSignal return:@YES] concat:[self cui_isVisible]];

  [self.view addSubview:self.blurView];
  [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.view);
  }];
}

#pragma mark -
#pragma mark Image capture
#pragma mark -

- (void)setupCaptureAnimation {
  @weakify(self);
  [self.viewModel.animateCapture subscribeNext:^(id) {
    @strongify(self);
    [self animateImageCapture];
  }];
}

- (void)animateImageCapture {
  self.view.alpha = 0;
  [UIView animateWithDuration:0.25 animations:^{
    self.view.alpha = 1;
  }];
}

@end

NS_ASSUME_NONNULL_END
