// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsPageView.h"

#import <LTKit/UIColor+Utilities.h>
#import <Wireframes/WFVideoView.h>

#import "SPXButtonsHorizontalLayoutView.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark SPXSubscriptionButtonsContainerView
#pragma mark -

@interface SPXSubscriptionButtonsContainerView ()

/// Label for the main title of the page.
@property (readonly, nonatomic) UILabel *titleLabel;

/// Label for the subtitle of the page.
@property (readonly, nonatomic) UILabel *subtitleLabel;

/// View containing \c titleLabel and \c subtitleLabel with padding between them.
@property (readonly, nonatomic) UIView *textsContainerView;

/// View containing \c textsContainerView with top and bottom margins.
@property (readonly, nonatomic) UIView *textsContainerWithMarginView;

/// View containing horizontally aligned buttons.
@property (readonly, nonatomic) SPXButtonsHorizontalLayoutView *subscriptionButtonsView;

@end

@implementation SPXSubscriptionButtonsContainerView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupContainerView];
  [self setupButtons];
  [self setupTextContainer];
  [self setupTitle];
  [self setupSubtitle];
}

- (void)setupContainerView {
  self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
  self.clipsToBounds = YES;
  self.layer.borderColor = [UIColor lt_colorWithHex:@"#363636"].CGColor;
  self.layer.borderWidth = 1;
  self.layer.cornerRadius = 6;
}

- (void)setupButtons {
  auto paddingView = [self addBottomPaddingView];

  _subscriptionButtonsView = [[SPXButtonsHorizontalLayoutView alloc] init];
  [self addSubview:self.subscriptionButtonsView];

  [self.subscriptionButtonsView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.equalTo(paddingView.mas_top);
    make.left.right.equalTo(self);
    make.height.equalTo(self).multipliedBy(0.558);
  }];
}

- (UIView *)addBottomPaddingView {
  auto paddingView = [[UIView alloc] init];
  paddingView.hidden = YES;
  [self addSubview:paddingView];

  [paddingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.left.right.equalTo(self);
    make.height.equalTo(self).multipliedBy(0.03).priorityHigh();
  }];

  return paddingView;
}

- (void)setupTextContainer {
  _textsContainerWithMarginView = [[UIView alloc] init];
  [self addSubview:self.textsContainerWithMarginView];
  [self.textsContainerWithMarginView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.left.right.equalTo(self);
    make.bottom.equalTo(self.subscriptionButtonsView.mas_top);
  }];

  _textsContainerView = [[UIView alloc] init];
  [self.textsContainerWithMarginView addSubview:self.textsContainerView];
  [self.textsContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.textsContainerWithMarginView);
    make.center.equalTo(self.textsContainerWithMarginView);
    make.height.equalTo(self).multipliedBy(0.25);
  }];
}

- (void)setupTitle {
  _titleLabel = [[UILabel alloc] init];
  self.titleLabel.adjustsFontSizeToFitWidth = YES;
  self.titleLabel.textAlignment = NSTextAlignmentCenter;
  [self.textsContainerView addSubview:self.titleLabel];

  [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self.textsContainerView);
    make.top.equalTo(self.textsContainerView);
    make.width.equalTo(self.textsContainerView).multipliedBy(0.92);
  }];
}

- (void)setupSubtitle {
  auto paddingView = [self addTitleBottomPaddingView];

  _subtitleLabel = [[UILabel alloc] init];
  self.subtitleLabel.numberOfLines = 0;
  self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
  self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
  [self.textsContainerView addSubview:self.subtitleLabel];

  [self.subtitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(paddingView.mas_bottom);
    make.centerX.equalTo(self.textsContainerView);
    make.width.equalTo(self.textsContainerView).multipliedBy(0.92);
  }];
}

- (UIView *)addTitleBottomPaddingView {
  auto paddingView = [[UIView alloc] init];
  paddingView.hidden = YES;
  [self.textsContainerView addSubview:paddingView];

  [paddingView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.textsContainerView);
    make.top.equalTo(self.titleLabel.mas_bottom);
    make.height.equalTo(self).multipliedBy(0.01).priorityHigh();
    make.height.mas_lessThanOrEqualTo(10);
  }];

  return paddingView;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setButtons:(NSArray<UIControl *> *)buttons {
  self.subscriptionButtonsView.buttons = buttons;
  [self setNeedsLayout];
}

- (NSArray<UIControl *> *)buttons {
  return self.subscriptionButtonsView.buttons;
}

- (void)setTitle:(nullable NSAttributedString *)title {
  self.titleLabel.attributedText = title;
  [self setNeedsLayout];
}

- (nullable NSAttributedString *)title {
  return self.titleLabel.attributedText;
}

- (void)setSubtitle:(nullable NSAttributedString *)subtitle {
  self.subtitleLabel.attributedText = subtitle;
  [self setNeedsLayout];
}

- (nullable NSAttributedString *)subtitle {
  return self.subtitleLabel.attributedText;
}

- (RACSignal<NSNumber *> *)buttonPressed {
  return self.subscriptionButtonsView.buttonPressed;
}

@end

#pragma mark -
#pragma mark SPXSubscriptionButtonsPageView
#pragma mark -

@interface SPXSubscriptionButtonsPageView ()

/// Video's width constraint, changed on landscape / portrait layout changes.
@property (nonatomic, strong) MASConstraint *videoWidthConstraint;

@end

@implementation SPXSubscriptionButtonsPageView

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  [self setupVideo];
  [self setupButtons];
}

- (void)setupVideo {
  _backgroundVideoView = [[WFVideoView alloc] initWithVideoProgressIntervalTime:1 playInLoop:YES];
  [self addSubview:self.backgroundVideoView];

  static const CGFloat kVideoAspectRatio = 1.109;
  [self.backgroundVideoView mas_makeConstraints:^(MASConstraintMaker *make) {
    self.videoWidthConstraint = make.width.equalTo(self);
    make.centerX.top.equalTo(self);
    make.height.equalTo(self.backgroundVideoView.mas_width).multipliedBy(kVideoAspectRatio);
  }];
}

- (void)setupButtons {
  _buttonsContainer = [[SPXSubscriptionButtonsContainerView alloc] init];
  [self addSubview:self.buttonsContainer];

  [self.buttonsContainer mas_makeConstraints:^(MASConstraintMaker *make) {
    make.bottom.centerX.equalTo(self);
    make.height.equalTo(self).multipliedBy(0.39).priorityMedium();
    make.height.mas_lessThanOrEqualTo(250);
    make.width.equalTo(self.buttonsContainer.mas_height).multipliedBy(1.6).with.priorityHigh();
    make.width.lessThanOrEqualTo(self).multipliedBy(0.92);
  }];
}

- (void)layoutSubviews {
  [super layoutSubviews];

  auto widthMultiplier = self.frame.size.width < self.frame.size.height ? 1 : 0.484;
  [self.videoWidthConstraint uninstall];
  [self.backgroundVideoView mas_updateConstraints:^(MASConstraintMaker *make) {
    self.videoWidthConstraint = make.width.equalTo(self).multipliedBy(widthMultiplier);
  }];
}

@end

NS_ASSUME_NONNULL_END
