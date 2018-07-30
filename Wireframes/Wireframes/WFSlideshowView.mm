// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFSlideshowView.h"

#import "WFSlideView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFSlideshowView () <WFSlideViewDelegate>

/// View for running the slideshow.
@property (readonly, nonatomic) WFSlideView *slideView;

/// View for containing the user-suplied incoming view.
@property (readonly, nonatomic) UIView *incomingView;

/// View for containing the user-suplied outgoing view.
@property (readonly, nonatomic) UIView *outgoingView;

/// Number of user-suplied views that were set as the subview of outgoingView since last call to
/// \c reloadSlides.
@property (nonatomic) NSUInteger outgoingSlidesCounter;

/// \c YES when sliding plays automatically.
@property (nonatomic) BOOL isPlaying;

/// \c YES when animation is currently in progress.
@property (nonatomic) BOOL animationInProgress;

/// Array of \c CALayer objects that are currently animating.
@property (readonly, nonatomic) NSArray<CALayer *> *animatingLayers;

@end

@implementation WFSlideshowView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.stillDuration = 1;
    self.transitionDuration = 1;
    self.transition = WFSlideshowTransitionCurtain;
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupImageViews];
  [self setupSlideView];
  [self updateTransition];
}

- (void)setupImageViews {
  _outgoingView = [[UIView alloc] initWithFrame:CGRectZero];
  _incomingView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)setupSlideView {
  _slideView = [[WFSlideView alloc] initWithFrame:CGRectZero];
  self.slideView.transition = WFSlideViewTransitionCurtain;
  self.slideView.delegate = self;
  self.slideView.panEnabled = NO;
  self.slideView.swipeEnabled = NO;
  self.slideView.progressIndicatorEnabled = YES;

  [self addSubview:self.slideView];
  [self.slideView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (void)pause {
  if (!self.isPlaying) {
    return;
  }
  self.isPlaying = NO;
}

- (void)pauseAndRemoveOngoingAnimations {
  [self pause];
  [self removeAllAnimations];
}

- (void)removeAllAnimations {
  [CATransaction begin];
  for (CALayer *layer in self.animatingLayers) {
    [layer removeAllAnimations];
  }
  [CATransaction commit];
}

- (NSArray<CALayer *> *)animatingLayers {
  auto animatingLayers = [[NSMutableArray<CALayer *> alloc] init];

  [animatingLayers addObjectsFromArray:self.slideView.animatingLayers];
  if (self.outgoingView.layer.animationKeys.count) {
    [animatingLayers addObject:self.outgoingView.layer];
  }
  if (self.incomingView.layer.animationKeys.count) {
    [animatingLayers addObject:self.incomingView.layer];
  }

  return animatingLayers;
}

- (void)play {
  if (self.isPlaying) {
    return;
  }
  self.isPlaying = YES;

  if (!self.animationInProgress) {
    [self animateTransition];
  }
}

- (void)animateTransition {
  if (![self numberOfImages]) {
    return;
  }

  switch (self.transition) {
    case WFSlideshowTransitionCurtain:
      [self animateTransitionWithCurtain];
      break;
    case WFSlideshowTransitionFade:
      [self animateTransitionWithFade];
      break;
  }
}

- (NSUInteger)numberOfImages {
  return [self.delegate numberOfSlidesInSlideshowView:self];
}

- (void)animateTransitionWithCurtain {
  const auto duration = self.transitionDuration;
  const auto delay = self.stillDuration;
  const auto options =
      UIViewAnimationOptionAllowUserInteraction |
      UIViewAnimationOptionBeginFromCurrentState |
      UIViewAnimationOptionCurveEaseOut;

  if (!self.animationInProgress) {
    [UIView performWithoutAnimation:^{
      [self.slideView layoutIfNeeded];
    }];
  }

  self.animationInProgress = YES;
  [UIView animateWithDuration:duration delay:delay options:options animations:^{
    self.slideView.progress = 1;
    [self.slideView layoutIfNeeded];
  } completion:^(BOOL) {
    [self completeTransitionAnimation];
  }];
}

- (void)animateTransitionWithFade {
  const auto duration = self.transitionDuration;
  const auto delay = self.stillDuration;
  const auto options =
      UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut;

  if (!self.animationInProgress) {
    [UIView performWithoutAnimation:^{
      [self.outgoingView layoutIfNeeded];
      [self.incomingView layoutIfNeeded];
    }];
  }

  self.animationInProgress = YES;
  [UIView animateWithDuration:duration delay:delay options:options animations:^{
    self.incomingView.alpha = 1;
  } completion:^(BOOL) {
    [self completeTransitionAnimation];
  }];
}

- (void)completeTransitionAnimation {
  self.animationInProgress = NO;
  [self showNext];

  switch (self.transition) {
    case WFSlideshowTransitionCurtain:
      self.slideView.progress = 0;
      break;
    case WFSlideshowTransitionFade:
      self.incomingView.alpha = 0;
      break;
  }

  [self.slideView layoutIfNeeded];
  if (self.isPlaying) {
    [self animateTransition];
  }
}

- (void)showNext {
  [self makeViewWithIndex:self.outgoingSlidesCounter theOnlySubviewOf:self.outgoingView];
  ++self.outgoingSlidesCounter;
  [self makeViewWithIndex:self.outgoingSlidesCounter theOnlySubviewOf:self.incomingView];
}

- (void)makeViewWithIndex:(NSUInteger)index theOnlySubviewOf:(UIView *)superview {
  [superview.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  auto subview = [self viewForIndex:index];
  if (subview) {
    [superview addSubview:subview];
    [subview mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(superview);
    }];
  }
}

- (nullable UIView *)viewForIndex:(NSUInteger)index {
  const auto count = [self numberOfImages];
  return count ? [self.delegate slideshowView:self viewForSlideIndex:index % count] : nil;
}

- (void)reloadSlides {
  [self pauseAndRemoveOngoingAnimations];
  self.outgoingSlidesCounter = 0;
  if (self.delegate) {
    [self showNext];
  }
}

#pragma mark -
#pragma mark UIView
#pragma mark -

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (!self.superview) {
    [self pause];
  }
}

#pragma mark -
#pragma mark WFSlideViewDelegate
#pragma mark -

- (void)slideViewDidBeginSlide:(WFSlideView __unused *)slideView {
  [self pause];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setDelegate:(nullable id<WFSlideshowViewDelegate>)delegate {
  _delegate = delegate;
  [self reloadSlides];
}

- (void)setTransition:(WFSlideshowTransition)transition {
  if (self.transition == transition) {
    return;
  }
  _transition = transition;
  [self reloadSlides];
  [self updateTransition];
}

- (void)updateTransition {
  switch (self.transition) {
    case WFSlideshowTransitionCurtain:
    [self setupCurtainTransition];
    break;
    case WFSlideshowTransitionFade:
    [self setupFadeTransition];
    break;
  }
}

- (void)setupCurtainTransition {
  [self.outgoingView removeFromSuperview];
  [self.incomingView removeFromSuperview];

  self.slideView.outgoingView = self.outgoingView;
  self.slideView.incomingView = self.incomingView;

  self.slideView.hidden = NO;
  self.outgoingView.alpha = 1;
  self.incomingView.alpha = 1;
}

- (void)setupFadeTransition {
  [self.outgoingView removeFromSuperview];
  [self.incomingView removeFromSuperview];

  [self addSubview:self.outgoingView];
  [self.outgoingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
  self.outgoingView.alpha = 1;

  [self addSubview:self.incomingView];
  [self.incomingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
  self.incomingView.alpha = 0;

  self.slideView.hidden = YES;
}

@end

NS_ASSUME_NONNULL_END
