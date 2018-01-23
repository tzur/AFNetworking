// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXMultiSubscriptionGradientButtonsFactory.h"

#import "SPXColorScheme.h"
#import "SPXSubscriptionButtonFormatter.h"
#import "SPXSubscriptionDescriptor.h"
#import "SPXSubscriptionGradientButtonsFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXMultiSubscriptionGradientButtonsFactory ()

/// Inner factory used to create single-app subscription buttons.
@property (readonly, nonatomic) SPXSubscriptionGradientButtonsFactory *singleAppButtonsFactory;

/// Inner factory used to create multi-app subscription buttons.
@property (readonly, nonatomic) SPXSubscriptionGradientButtonsFactory *multiAppButtonsFactory;

@end

@implementation SPXMultiSubscriptionGradientButtonsFactory

- (instancetype)initWithColorScheme:(SPXColorScheme *)colorScheme
                          formatter:(SPXSubscriptionButtonFormatter *)formatter {
  return [self initWithBottomGradientColors:colorScheme.mainGradientColors
               multiAppBottomGradientColors:colorScheme.multiAppGradientColors
                                  formatter:formatter];
}

- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                multiAppBottomGradientColors:(NSArray<UIColor *> *)multiAppBottomGradientColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter {
  if (self = [super init]) {
    auto bottomNonGradientColors = @[
      bottomGradientColors.firstObject,
      bottomGradientColors.firstObject
    ];
    _singleAppButtonsFactory = [[SPXSubscriptionGradientButtonsFactory alloc]
                                initWithBottomGradientColors:bottomNonGradientColors
                                highlightedBottomGradientColors:bottomGradientColors
                                formatter:formatter];
    auto multiAppBottomNonGradientColors = @[
      multiAppBottomGradientColors.firstObject,
      multiAppBottomGradientColors.firstObject
    ];
    _multiAppButtonsFactory = [[SPXSubscriptionGradientButtonsFactory alloc]
                               initWithBottomGradientColors:multiAppBottomNonGradientColors
                               highlightedBottomGradientColors:multiAppBottomGradientColors
                               formatter:formatter];
  }
  return self;
}

- (UIControl *)createSubscriptionButtonWithSubscriptionDescriptor:
    (SPXSubscriptionDescriptor *)subscriptionDescriptor atIndex:(NSUInteger)index
                                                          outOf:(NSUInteger)buttonsCount
                                                  isHighlighted:(BOOL)isHighlighted {
  auto factory = subscriptionDescriptor.isMultiAppSubscription ?
      self.multiAppButtonsFactory : self.singleAppButtonsFactory;

  return (SPXSubscriptionGradientButton *)[factory
      createSubscriptionButtonWithSubscriptionDescriptor:subscriptionDescriptor atIndex:index
                                                   outOf:buttonsCount isHighlighted:isHighlighted];
}

@end

NS_ASSUME_NONNULL_END
