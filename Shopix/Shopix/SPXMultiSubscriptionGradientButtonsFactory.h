// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsFactory.h"

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme, SPXSubscriptionButtonFormatter;

/// Buttons factory that creates \c SPXSubscriptionGradientButton for single-app or multi-app
/// subscription, the subscription period and price are set as the top and bottom texts of the
/// button respectively. Buttons are identified as multi-app buttons by the multi-app marker as
/// defined by Bazaar.
@interface SPXMultiSubscriptionGradientButtonsFactory : NSObject <SPXSubscriptionButtonsFactory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c colorScheme for mapping between the colors scheme to the buttons colors.
/// \c bottomGradientColors are set to \c mainGradientColor for single-app buttons and
/// \c multiAppGradientColors for multi-app buttons, \c periodTextColor is set to
/// \c darkTextColor \c priceTextColor is set to \c textColor. \c fullPriceTextColor is set to
/// \c grayedTextColor. \c formatter is set to the default formatter with the given colors.
/// \c productsInfoProvider is used to identify if a subscription is a multi-app subscription.
- (instancetype)initWithColorScheme:(SPXColorScheme *)colorScheme;

/// Initializes with \c bottomGradientColors for single-app buttons gradient colors,
/// \c multiAppBottomGradientColors for multi-app buttons gradient colors \c periodTextColor,
/// \c priceTextColor and \c fullPriceTextColor are the period and prices texts colors. \c formatter
/// is set to the default formatter with the given colors. \c productsInfoProvider is used to
/// identify if a subscription is a multi-app subscription.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                multiAppBottomGradientColors:(NSArray<UIColor *> *)multiAppBottomGradientColors
                             periodTextColor:(UIColor *)periodTextColor
                          fullPriceTextColor:(UIColor *)fullPriceTextColor
                              priceTextColor:(UIColor *)priceTextColor;

/// Initializes with \c bottomGradientColors for single-app buttons gradient colors,
/// \c multiAppBottomGradientColors for multi-app buttons gradient colors and \c formatter for the
/// subscription period and price texts. \c productsInfoProvider is used to identify if a
/// subscription is a multi-app subscription.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                multiAppBottomGradientColors:(NSArray<UIColor *> *)multiAppBottomGradientColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
