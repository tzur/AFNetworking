// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionGradientButton.h"

NS_ASSUME_NONNULL_BEGIN

@class SPXSubscriptionButtonFormatter;

/// Buttons factory that creates \c SPXSubscriptionGradientButton, the subscription period and
/// price are set as the top and bottom texts of the button respectively.
@interface SPXSubscriptionGradientButtonsFactory : NSObject <SPXSubscriptionButtonsFactory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c bottomGradientColors for the buttons gradient colors, \c periodTextColor,
/// \c priceTextColor and \c fullPriceTextColor are the period and prices texts colors. \c formatter
/// is set to the default formatter with the given colors.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                             periodTextColor:(UIColor *)periodTextColor
                          fullPriceTextColor:(UIColor *)fullPriceTextColor
                              priceTextColor:(UIColor *)priceTextColor;

/// Initializes with \c bottomGradientColors for the buttons gradient colors and \c formatter
/// for the subscription period and price texts.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
