// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanPromotionCell.h"

#import "EUISMYourPlanPromotionViewModel.h"
#import "UIColor+EnlightUI.h"
#import "UIFont+EnlightUI.h"

NS_ASSUME_NONNULL_BEGIN

using namespace eui;

@interface EUISMYourPlanPromotionCell ()

/// Label for the promotion text.
@property (readonly, nonatomic) UILabel *promotionLabel;

/// Button for upgrading to promoted subscription.
@property (readonly, nonatomic) UIButton *upgradeButton;

@end

@implementation EUISMYourPlanPromotionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(nullable NSString *)reuseIdentifier {
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    [self setupUpgradeButton];
    [self setupPromotionLabel];
    self.backgroundColor = [UIColor eui_secondaryDarkColor];
  }
  return self;
}

- (void)setupUpgradeButton {
  _upgradeButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [self.upgradeButton setTitleColor:[UIColor eui_whiteColor] forState:UIControlStateNormal];
  auto upgrade = _LDefault(@"UPGRADE", @"Label on a button for upgrading the subscription to "
                           "subscription that is longer or allows more services");
  [self.upgradeButton setTitle:upgrade forState:UIControlStateNormal];
  RAC(self.upgradeButton, backgroundColor) = RACObserve(self, viewModel.upgradeButtonColor);
  self.upgradeButton.clipsToBounds = YES;

  [self addSubview:self.upgradeButton];
  [self.upgradeButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self);
    make.right.equalTo(self).offset(-20);
    make.width.greaterThanOrEqualTo(@92).priorityHigh();
    make.width.lessThanOrEqualTo(@102).priorityHigh();
    make.width.equalTo(self).multipliedBy(0.27).priorityMedium();
    make.height.greaterThanOrEqualTo(@27).priorityHigh();
    make.height.lessThanOrEqualTo(@30).priorityHigh();
    make.height.equalTo(self.mas_width).multipliedBy(0.08).priorityMedium();
  }];
}

- (void)setupPromotionLabel {
  _promotionLabel = [[UILabel alloc] init];
  RAC(self.promotionLabel, textColor) = RACObserve(self, viewModel.promotionTextColor);
  RAC(self.promotionLabel, text) = RACObserve(self, viewModel.promotionText);

  [self addSubview:self.promotionLabel];
  [self.promotionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerY.equalTo(self.upgradeButton);
    make.left.equalTo(self).offset(20);
  }];
}

- (void)layoutSubviews {
  auto promotionFontSize = std::clamp(CGRectGetWidth(self.bounds) * 0.035, 11., 14.);
  self.promotionLabel.font = [UIFont eui_additionalsFontWithSize:promotionFontSize];
  auto upgradeButtonFontSize = std::clamp(CGRectGetWidth(self.bounds) * 0.035, 11., 13.);
  self.upgradeButton.titleLabel.font = [UIFont eui_additionalsFontWithSize:upgradeButtonFontSize];
  [super layoutSubviews];
  self.upgradeButton.layer.cornerRadius = self.upgradeButton.bounds.size.height / 2.;
}

- (void)setViewModel:(nullable id<EUISMYourPlanPromotionViewModel>)viewModel {
  _viewModel = viewModel;
  if (!viewModel) {
    return;
  }
  auto upgradeButtonPressed =
      [self.upgradeButton rac_signalForControlEvents:UIControlEventTouchUpInside];
  self.viewModel.upgradeRequested = [upgradeButtonPressed mapReplace:RACUnit.defaultUnit];
}

@end

NS_ASSUME_NONNULL_END
