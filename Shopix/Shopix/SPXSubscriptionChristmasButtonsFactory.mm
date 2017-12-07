// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionChristmasButtonsFactory.h"

#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionGradientButtonsFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionChristmasButtonsFactory ()

/// Inner factory to create gradient buttons.
@property (readonly, nonatomic) SPXSubscriptionGradientButtonsFactory *gradientButtonsFactory;

@end

@implementation SPXSubscriptionChristmasButtonsFactory

- (instancetype)init {
  if (self = [super init]) {
    auto christmasRedColor = [UIColor colorWithRed:0.92 green:0.19 blue:0.23 alpha:1.0];
    auto periodTextColor = [UIColor colorWithRed:0.2 green:0.18 blue:0.21 alpha:1.0];
    auto fullPriceTextColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    _gradientButtonsFactory = [[SPXSubscriptionGradientButtonsFactory alloc]
                               initWithBottomGradientColors:@[christmasRedColor, christmasRedColor]
                               periodTextColor:periodTextColor
                               fullPriceTextColor:fullPriceTextColor
                               priceTextColor:[UIColor whiteColor]];
  }
  return self;
}

- (UIControl *)createSubscriptionButtonWithSubscriptionDescriptor:
    (SPXSubscriptionDescriptor *)subscriptionDescriptor atIndex:(NSUInteger)index
                                                          outOf:(NSUInteger)buttonsCount {
  auto gradientButton = [self.gradientButtonsFactory
                         createSubscriptionButtonWithSubscriptionDescriptor:subscriptionDescriptor
                         atIndex:index outOf:buttonsCount];

  NSString *imageName;
  if (index == 0) {
    imageName = @"christmas_button_left";
  } else if (buttonsCount > 0 && index == buttonsCount - 1) {
    imageName = @"christmas_button_right";
  } else {
    imageName = @"christmas_button_middle";
  }

  auto shopixBundle = [NSBundle bundleWithIdentifier:@"com.lightricks.ShopixBundle"];
  auto image = [UIImage imageNamed:imageName inBundle:shopixBundle
     compatibleWithTraitCollection:nil];
  auto christmasButton = [[UIControl alloc] init];
  [[gradientButton rac_signalForControlEvents:UIControlEventTouchUpInside]
   subscribeNext:^(UIControl *) {
     [christmasButton sendActionsForControlEvents:UIControlEventTouchUpInside];
   }];
  [christmasButton addSubview:gradientButton];
  [gradientButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(christmasButton);
  }];

  auto imageView = [[UIImageView alloc] initWithImage:image];
  [christmasButton addSubview:imageView];
  [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(christmasButton);
    make.height.equalTo(christmasButton).multipliedBy(1.65);
    make.width.equalTo(imageView.mas_height).multipliedBy(0.677);
  }];
  return christmasButton;
}

@end

NS_ASSUME_NONNULL_END
