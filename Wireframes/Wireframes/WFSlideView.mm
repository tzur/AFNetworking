// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Hadar.

#import "WFSlideView.h"

#import <LTKit/UIColor+Utilities.h>

#import "CALayer+Enumeration.h"
#import "WFGradientView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WFSlideView () <UIGestureRecognizerDelegate>

/// Superview for \c incommingView used for clipping.
@property (readonly, nonatomic) UIView *incomingClipView;

/// Superview for \c outgoingView used for clipping.
@property (readonly, nonatomic) UIView *outgoingClipView;

/// Constraint for the width attribute of the \c incomingClipView.
@property (nonatomic) MASConstraint *incomingWidthConstraint;

/// Recognizer for pan and swipe gestures.
@property (readonly, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

/// Progress indicator view shown during transition.
@property (readonly, nonatomic) WFGradientView *progressIndicatorView;

@end

@implementation WFSlideView

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
    self.transition = WFSlideViewTransitionCurtain;
    self.panEnabled = YES;
    self.swipeEnabled = YES;
    self.progressIndicatorEnabled = NO;
  }
  return self;
}

- (void)setup {
  [self setupClipViews];
  [self setupPanning];
  [self setupProgressIndicatorView];
}

- (void)setupClipViews {
  _outgoingClipView = [self createClipView];
  _incomingClipView = [self createClipView];
  [self addSubview:self.outgoingClipView];
  [self addSubview:self.incomingClipView];

  [self.incomingClipView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.bottom.left.equalTo(self);
  }];

  [self.outgoingClipView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.top.bottom.equalTo(self);
    make.left.equalTo(self.incomingClipView.mas_right);
  }];

  [self updateProgress];
}

- (UIView *)createClipView {
  UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
  view.clipsToBounds = YES;
  return view;
}

- (void)updateProgress {
  [self.incomingWidthConstraint uninstall];
  [self.incomingClipView mas_makeConstraints:^(MASConstraintMaker *make) {
    self.incomingWidthConstraint = make.width.equalTo(self.mas_width).multipliedBy(self.progress);
  }];

  [self.outgoingClipView setNeedsLayout];
  [self.incomingClipView setNeedsLayout];
}

- (void)setupPanning {
  _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(didPan:)];
  self.panGestureRecognizer.delegate = self;
  self.panGestureRecognizer.enabled = NO;
  [self addGestureRecognizer:self.panGestureRecognizer];
}

- (void)setupProgressIndicatorView {
  _progressIndicatorView = [WFGradientView horizontalGradientWithLeftColor:nil rightColor:nil];
  self.progressIndicatorView.accessibilityIdentifier = @"ProgressIndicator";
  self.progressIndicatorColor = [UIColor blackColor];
  [self addSubview:self.progressIndicatorView];

  [self.progressIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.width.equalTo(self.mas_width).multipliedBy(0.07);
    make.right.top.bottom.equalTo(self.incomingClipView);
  }];

  RAC(self, progressIndicatorView.hidden) = [RACObserve(self, progressIndicatorEnabled) not];
}

#pragma mark -
#pragma mark Sliding
#pragma mark -

- (void)didPan:(UIPanGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    if ([self.delegate respondsToSelector:@selector(slideViewDidBeginSlide:)]) {
      [self.delegate slideViewDidBeginSlide:self];
    }
  }

  CGPoint translation = [gestureRecognizer translationInView:self];
  [gestureRecognizer setTranslation:CGPointZero inView:self];

  CGFloat delta = translation.x / self.bounds.size.width;
  self.progress += delta;

  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    if ([self.delegate respondsToSelector:@selector(slideViewDidEndSlide:)]) {
      [self.delegate slideViewDidEndSlide:self];
    }

    CGPoint velocity = [gestureRecognizer velocityInView:self];
    [self didEndPanWithVelocity:velocity];
  }
}

- (void)didEndPanWithVelocity:(CGPoint)velocity {
  if (self.swipeEnabled) {
    CGFloat springVelocity = [self springVelocityForPanVelocity:velocity.x];
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1
          initialSpringVelocity:springVelocity
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.progress = (velocity.x > 0) ? 1 : 0;
                       [self layoutIfNeeded];
                     } completion:^(BOOL) {
                       [self reportSlideAnimationEnded];
                     }];
  } else {
    [self reportSlideAnimationEnded];
  }
}

- (void)reportSlideAnimationEnded {
  if ([self.delegate respondsToSelector:@selector(slideViewDidEndSlideAnimation:)]) {
    [self.delegate slideViewDidEndSlideAnimation:self];
  }
}

- (CGFloat)springVelocityForPanVelocity:(CGFloat)velocity {
  CGFloat startWidth = self.incomingClipView.frame.size.width;
  CGFloat distance = (velocity <= 0) ? startWidth : self.bounds.size.width - startWidth;
  return std::abs(velocity) / distance;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
#pragma mark -

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
  CGPoint point = [gestureRecognizer translationInView:self];
  return std::abs(point.x) > std::abs(point.y);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer __unused *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:
    (UIGestureRecognizer __unused *)otherGestureRecognizer {
  return NO;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setProgress:(CGFloat)progress {
  _progress = std::clamp(progress, 0, 1);
  [self updateProgress];
}

- (void)setPanEnabled:(BOOL)panEnabled {
  _panEnabled = panEnabled;
  self.panGestureRecognizer.enabled = panEnabled;
}

- (NSArray<CALayer *> *)animatingLayers {
  NSMutableArray<CALayer *> *animatingLayers = [[NSMutableArray alloc] init];
  [self.layer wf_enumerateLayersUsingBlock:^(CALayer *layer) {
    if (layer.animationKeys.count) {
      [animatingLayers addObject:layer];
    }
  }];
  return animatingLayers;
}

- (void)setProgressIndicatorColor:(UIColor *)color {
  if ([self.progressIndicatorColor isEqual:color]) {
    return;
  }
  _progressIndicatorColor = color;
  self.progressIndicatorView.startColor = [self.progressIndicatorColor colorWithAlphaComponent:0.0];
  self.progressIndicatorView.endColor = [self.progressIndicatorColor colorWithAlphaComponent:0.5];
}

- (void)setTransition:(WFSlideViewTransition)transition {
  _transition = transition;
  [self setupTransition];
}

- (void)setupTransition {
  switch (self.transition) {
    case WFSlideViewTransitionCurtain:
      [self setupCurtain];
      break;
    case WFSlideViewTransitionSlide:
      [self setupSlide];
      break;
  }
  [self updateProgress];
}

- (void)setupCurtain {
  if (self.incomingView) {
    [self.incomingView removeFromSuperview];
    [self.incomingClipView addSubview:nn(self.incomingView)];

    [self.incomingView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.size.equalTo(self);
      make.center.equalTo(self);
    }];
  }

  if (self.outgoingView) {
    [self.outgoingView removeFromSuperview];
    [self.outgoingClipView addSubview:nn(self.outgoingView)];

    [self.outgoingView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.size.equalTo(self);
      make.center.equalTo(self);
    }];
  }
}

- (void)setupSlide {
  if (self.incomingView) {
    [self.incomingView removeFromSuperview];
    [self.incomingClipView addSubview:nn(self.incomingView)];

    [self.incomingView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.size.equalTo(self);
      make.top.equalTo(self);
      make.right.equalTo(self.incomingClipView.mas_right);
    }];
  }

  if (self.outgoingView) {
    [self.outgoingView removeFromSuperview];
    [self.outgoingClipView addSubview:nn(self.outgoingView)];

    [self.outgoingView mas_remakeConstraints:^(MASConstraintMaker *make) {
      make.size.equalTo(self);
      make.top.equalTo(self);
      make.left.equalTo(self.outgoingClipView.mas_left);
    }];
  }
}

- (void)setIncomingView:(nullable UIView *)incomingView {
  _incomingView = incomingView;
  [self setupTransition];
}

- (void)setOutgoingView:(nullable UIView *)outgoingView {
  _outgoingView = outgoingView;
  [self setupTransition];
}

@end

NS_ASSUME_NONNULL_END
