// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionGradientButtonsFactory.h"

#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionGradientButtonsFactory ()

/// Gradient colors for the bottom part of the buttons.
@property (readonly, nonatomic) NSArray<UIColor *> *bottomGradientColors;

/// Text formatter for the subscription price and period.
@property (readonly, nonatomic) SPXSubscriptionButtonFormatter *formatter;

@end

@implementation SPXSubscriptionGradientButtonsFactory

- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter {
  if (self = [super init]) {
    _bottomGradientColors = [bottomGradientColors copy];
    _formatter = formatter;
  }
  return self;
}

- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                             periodTextColor:(UIColor *)periodTextColor
                          fullPriceTextColor:(UIColor *)fullPriceTextColor
                              priceTextColor:(UIColor *)priceTextColor {
  auto formatter = [[SPXSubscriptionButtonFormatter alloc] initWithPeriodTextColor:periodTextColor
      priceTextColor:priceTextColor fullPriceTextColor:fullPriceTextColor];
  return [self initWithBottomGradientColors:bottomGradientColors formatter:formatter];
}

- (UIButton *)createSubscriptionButtonWithSubscriptionDescriptor:
    (SPXSubscriptionDescriptor *)subscriptionDescriptor {
  auto subscriptionButton = [[SPXSubscriptionGradientButton alloc] init];
  subscriptionButton.exclusiveTouch = YES;
  subscriptionButton.topText =
      [self.formatter periodTextForSubscription:subscriptionDescriptor.productIdentifier
                                  monthlyFormat:YES];
  subscriptionButton.bottomGradientColors = self.bottomGradientColors;

  SPXSubscriptionButtonFormatter *formatter = self.formatter;
  RAC(subscriptionButton, bottomText) = [[RACObserve(subscriptionDescriptor, priceInfo)
      deliverOnMainThread]
      map:^NSAttributedString * _Nullable (BZRProductPriceInfo * _Nullable priceInfo) {
        return priceInfo ?
            [formatter joinedPriceTextForSubscription:subscriptionDescriptor.productIdentifier
                                            priceInfo:priceInfo monthlyFormat:YES] : nil;
      }];

  return subscriptionButton;
}

@end

NS_ASSUME_NONNULL_END
