// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIPreviewViewController.h"

#import "CUIFocusIconMode.h"
#import "CUIFocusView.h"
#import "CUILayerView.h"
#import "CUIPreviewViewModel.h"
#import "CUISharedTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface CUIPreviewViewController ()

/// View model to determine the properties displayed by this view controller.
@property (readonly, nonatomic) CUIPreviewViewModel *viewModel;

/// View showing the preview image.
@property (readonly, nonatomic) CUILayerView *previewView;

/// Focus indicator.
@property (readonly, nonatomic) CUIFocusView *focusView;

/// Recognizer for tap gestures, used to control the camera focus.
@property (readonly, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

/// Recognizer for pinch gestures, used to control the camera zoom.
@property (readonly, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

@end

@implementation CUIPreviewViewController

- (instancetype)initWithViewModel:(CUIPreviewViewModel *)viewModel {
  if (self = [super initWithNibName:nil bundle:nil]) {
    _viewModel = viewModel;
  }
  return self;
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

  self.previewView.frame = self.view.bounds;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [self setupPreviewView:self.viewModel.previewLayer];
  [self setupFocusView];
}

#pragma mark -
#pragma mark Preview view
#pragma mark -

- (void)setupPreviewView:(CALayer *)previewLayer {
  _previewView = [[CUILayerView alloc] initWithLayer:previewLayer];
  [self.view addSubview:self.previewView];
  RAC(self.previewView, hidden) = RACObserve(self, viewModel.previewHidden);

  _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.viewModel
                                                                  action:@selector(previewTapped:)];
  [self.previewView addGestureRecognizer:self.tapGestureRecognizer];
  RAC(self.tapGestureRecognizer, enabled) = RACObserve(self, viewModel.tapEnabled);

  _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc]
      initWithTarget:self.viewModel action:@selector(previewPinched:)];
  [self.previewView addGestureRecognizer:self.pinchGestureRecognizer];
  RAC(self.pinchGestureRecognizer, enabled) = RACObserve(self, viewModel.pinchEnabled);
}

#pragma mark -
#pragma mark Focus view
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
  [[self.viewModel.focusModeAndPosition
      deliverOnMainThread]
      subscribeNext:^(CUIFocusIconMode *focusIconAction) {
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

@end

NS_ASSUME_NONNULL_END
