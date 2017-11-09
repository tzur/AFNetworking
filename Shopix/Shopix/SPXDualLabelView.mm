// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXDualLabelView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXDualLabelView ()

/// Top label of the button.
@property (readonly, nonatomic) UILabel *topLabel;

/// Bottom label of the button.
@property (readonly, nonatomic) UILabel *bottomLabel;

@end

@implementation SPXDualLabelView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupTopLabel];
  [self setupBottomLabel];
  self.lablesRatio = 0.56;
}

- (void)setupTopLabel {
  _topLabel = [self createLabel];
  [self addSubview:self.topLabel];

  [self.topLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self);
  }];
}

- (void)setupBottomLabel {
  _bottomLabel = [self createLabel];
  [self addSubview:self.bottomLabel];

  [self.bottomLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.left.right.equalTo(self);
    make.top.equalTo(self.topLabel.mas_bottom);
  }];
}

- (UILabel *)createLabel {
  auto label = [[UILabel alloc] initWithFrame:CGRectZero];

  label.lineBreakMode = NSLineBreakByWordWrapping;
  label.numberOfLines = 0;
  label.textAlignment = NSTextAlignmentCenter;

  return label;
}

- (void)setLablesRatio:(CGFloat)lablesRatio {
  _lablesRatio = lablesRatio;

  [self.topLabel mas_updateConstraints:^(MASConstraintMaker *make) {
    make.height.equalTo(self).multipliedBy(lablesRatio);
  }];
}

- (void)setTopText:(nullable NSAttributedString *)topText {
  self.topLabel.attributedText = topText;
}

- (nullable NSAttributedString *)topText {
  return self.topLabel.attributedText;
}

- (void)setBottomText:(nullable NSAttributedString *)bottomText {
  self.bottomLabel.attributedText = bottomText;
}

- (nullable NSAttributedString *)bottomText {
  return self.bottomLabel.attributedText;
}

- (void)setTopBackgroundColor:(nullable UIColor *)topBackgroundColor {
  self.topLabel.backgroundColor = topBackgroundColor;
}

- (nullable UIColor *)topBackgroundColor {
  return self.topLabel.backgroundColor;
}

- (void)setBottomBackgroundColor:(nullable UIColor *)bottomBackgroundColor {
  self.bottomLabel.backgroundColor = bottomBackgroundColor;
}

- (nullable UIColor *)bottomBackgroundColor {
  return self.bottomLabel.backgroundColor;
}

@end

NS_ASSUME_NONNULL_END
