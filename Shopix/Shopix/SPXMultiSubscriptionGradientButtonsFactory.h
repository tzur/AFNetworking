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
/// \c multiAppGradientColors for multi-app buttons. \c formatter used for creating the subscription
/// period and price texts.
- (instancetype)initWithColorScheme:(SPXColorScheme *)colorScheme
                          formatter:(SPXSubscriptionButtonFormatter *)formatter;

/// Initializes with \c bottomGradientColors for single-app buttons gradient colors,
/// \c multiAppBottomGradientColors for multi-app buttons gradient colors and \c formatter for the
/// subscription period and price texts.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
                multiAppBottomGradientColors:(NSArray<UIColor *> *)multiAppBottomGradientColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
