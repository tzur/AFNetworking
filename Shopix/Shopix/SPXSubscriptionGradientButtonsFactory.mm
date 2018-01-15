// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionGradientButtonsFactory.h"

#import "SPXColorScheme.h"
#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionGradientButtonsFactory ()

/// Gradient colors for the bottom part of the buttons.
@property (readonly, nonatomic) NSArray<UIColor *> *bottomGradientColors;

/// Gradient colors for the bottom part of the highlighted buttons.
@property (readonly, nonatomic) NSArray<UIColor *> *highlightedBottomColors;

/// Text formatter for the subscription price and period.
@property (readonly, nonatomic) SPXSubscriptionButtonFormatter *formatter;

@end

@implementation SPXSubscriptionGradientButtonsFactory

- (instancetype)init {
  return [self initWithColorScheme:nn([JSObjection defaultInjector][[SPXColorScheme class]])];
}

- (instancetype)initWithColorScheme:(SPXColorScheme *)colorScheme {
  return [self initWithBottomGradientColors:@[colorScheme.mainColor, colorScheme.mainColor]
            highlightedBottomGradientColors:colorScheme.mainGradientColors
                            periodTextColor:colorScheme.darkTextColor
                         fullPriceTextColor:colorScheme.grayedTextColor
                             priceTextColor:colorScheme.textColor];
}

- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
             highlightedBottomGradientColors:(nullable NSArray<UIColor *> *)highlightedBottomColors
                             periodTextColor:(UIColor *)periodTextColor
                          fullPriceTextColor:(UIColor *)fullPriceTextColor
                              priceTextColor:(UIColor *)priceTextColor {
  auto formatter = [[SPXSubscriptionButtonFormatter alloc] initWithPeriodTextColor:periodTextColor
      priceTextColor:priceTextColor fullPriceTextColor:fullPriceTextColor];
  return [self initWithBottomGradientColors:bottomGradientColors
            highlightedBottomGradientColors:highlightedBottomColors formatter:formatter];
}

- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
             highlightedBottomGradientColors:(nullable NSArray<UIColor *> *)highlightedBottomColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter {
  if (self = [super init]) {
    _bottomGradientColors = [bottomGradientColors copy];
    _highlightedBottomColors = [highlightedBottomColors copy];
    _formatter = formatter;
  }
  return self;
}

- (UIControl *)createSubscriptionButtonWithSubscriptionDescriptor:
    (SPXSubscriptionDescriptor *)subscriptionDescriptor atIndex:(NSUInteger __unused)index
                                                          outOf:(NSUInteger __unused)buttonsCount
                                                  isHighlighted:(BOOL)isHighlighted {
  auto subscriptionButton = [[SPXSubscriptionGradientButton alloc] init];
  subscriptionButton.exclusiveTouch = YES;
  subscriptionButton.enabled = NO;
  subscriptionButton.topText =
      [self.formatter billingPeriodTextForSubscription:subscriptionDescriptor
                                         monthlyFormat:YES];
  subscriptionButton.bottomGradientColors = isHighlighted && self.highlightedBottomColors ?
      self.highlightedBottomColors : self.bottomGradientColors;
  if (isHighlighted) {
    subscriptionButton.borderColor = self.highlightedBottomColors ?
        [self highlightedColor:self.highlightedBottomColors.lastObject] : nil;
  }

  SPXSubscriptionButtonFormatter *formatter = self.formatter;
  RAC(subscriptionButton, enabled) = [[RACObserve(subscriptionDescriptor, priceInfo)
      deliverOnMainThread]
      map:^NSNumber *(BZRProductPriceInfo * _Nullable priceInfo) {
        return @(priceInfo != nil);
      }];
  RAC(subscriptionButton, bottomText) = [[RACObserve(subscriptionDescriptor, priceInfo)
      deliverOnMainThread]
      map:^NSAttributedString * _Nullable (BZRProductPriceInfo * _Nullable priceInfo) {
        return priceInfo ?
            [formatter joinedPriceTextForSubscription:subscriptionDescriptor
                                        monthlyFormat:YES] : nil;
      }];

  return subscriptionButton;
}

- (UIColor *)highlightedColor:(UIColor *)color {
  CGFloat hue, saturation, brightness, alpha;
  [color getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

  return [UIColor colorWithHue:hue saturation:saturation brightness:brightness * 1.24 alpha:alpha];
}

@end

NS_ASSUME_NONNULL_END
