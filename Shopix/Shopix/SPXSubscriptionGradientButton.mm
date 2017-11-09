// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionGradientButton.h"

#import <Wireframes/WFGradientView.h>

#import "SPXDualLabelView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionGradientButton ()

/// Bottom horizontal gradient view.
@property (readonly, nonatomic) WFGradientView *bottomGradientView;

/// Dual label above the button.
@property (readonly, nonatomic) SPXDualLabelView *dualLabelView;

/// Bottom overlay view, shown when the button is highlighted.
@property (readonly, nonatomic) UIView *bottomOverlay;

@end

@implementation SPXSubscriptionGradientButton

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  self.layer.cornerRadius = 7;
  self.clipsToBounds = YES;
  self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
  self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

  [self setupDualLabel];
  [self setupBottomGradient];
  [self setupBottomOverlay];
}

- (void)setupDualLabel {
  _dualLabelView = [[SPXDualLabelView alloc] init];
  [self addSubview:self.dualLabelView];

  self.dualLabelView.userInteractionEnabled = NO;
  self.dualLabelView.topBackgroundColor = [UIColor whiteColor];
  [self.dualLabelView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

- (void)setupBottomGradient {
  _bottomGradientView = [[WFGradientView alloc] init];
  [self insertSubview:self.bottomGradientView belowSubview:self.dualLabelView];

  self.bottomGradientView.userInteractionEnabled = NO;
  [self.bottomGradientView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.left.right.equalTo(self);
    make.height.equalTo(self).multipliedBy(1 - self.dualLabelView.lablesRatio);
  }];
}

- (void)setupBottomOverlay {
  _bottomOverlay = [[UIView alloc] initWithFrame:CGRectZero];
  [self addSubview:self.bottomOverlay];

  self.bottomOverlay.hidden = YES;
  self.bottomOverlay.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
  [self.bottomOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self.bottomGradientView);
  }];
}

- (void)setHighlighted:(BOOL)highlighted {
  [super setHighlighted:highlighted];
  self.bottomOverlay.hidden = !highlighted;
}

- (void)setTopText:(nullable NSAttributedString *)topText {
  self.dualLabelView.topText = topText;
}

- (nullable NSAttributedString *)topText {
  return self.dualLabelView.topText;
}

- (void)setBottomText:(nullable NSAttributedString *)bottomText {
  self.dualLabelView.bottomText = bottomText;
}

- (nullable NSAttributedString *)bottomText {
  return self.dualLabelView.bottomText;
}

- (void)setTopBackgroundColor:(nullable UIColor *)topBackgroundColor {
  self.dualLabelView.topBackgroundColor = topBackgroundColor;
}

- (nullable UIColor *)topBackgroundColor {
  return self.dualLabelView.topBackgroundColor;
}

- (void)setBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors {
  self.bottomGradientView.colors = bottomGradientColors;
}

- (NSArray<UIColor *> *)bottomGradientColors {
  return self.bottomGradientView.colors;
}

@end

NS_ASSUME_NONNULL_END
