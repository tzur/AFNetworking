// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXRestorePurchasesButton.h"

#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@implementation SPXRestorePurchasesButton

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    [self setup];
  }
  return self;
}

- (void)setup {
  auto restorePurchasesTitle = _LDefault(@"Restore Purchases", @"Label on a button that restored "
                                         "previously purchased products");
  [self setTitle:restorePurchasesTitle forState:UIControlStateNormal];
  self.titleLabel.font = [UIFont spx_standardFontWithSizeRatio:0.019 minSize:13 maxSize:16];
  self.exclusiveTouch = YES;
}

- (void)setTextColor:(UIColor *)textColor {
  _textColor = textColor;
  [self setTitleColor:textColor forState:UIControlStateNormal];
  [self setTitleColor:[textColor colorWithAlphaComponent:0.75] forState:UIControlStateHighlighted];
}

@end

NS_ASSUME_NONNULL_END
