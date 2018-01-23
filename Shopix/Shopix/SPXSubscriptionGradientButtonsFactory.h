// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonsFactory.h"
#import "SPXSubscriptionGradientButton.h"

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme, SPXSubscriptionButtonFormatter;

/// Buttons factory that creates \c SPXSubscriptionGradientButton, the subscription period and
/// price are set as the top and bottom texts of the button respectively. The button will have
/// highlighted border and colors if marked as highlighted.
@interface SPXSubscriptionGradientButtonsFactory : NSObject <SPXSubscriptionButtonsFactory>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c colorScheme for mapping between the colors scheme to the buttons colors.
/// \c bottomGradientColors are set to \c mainColor, \c highlightedBottomColors is set to
/// \c mainGradientColors. \c formatter used for creating the subscription period and price texts.
- (instancetype)initWithColorScheme:(SPXColorScheme *)colorScheme
                          formatter:(SPXSubscriptionButtonFormatter *)formatter;

/// Initializes with \c bottomGradientColors for normal buttons gradient colors,
/// \c highlightedBottomColors for the highlighted buttons and \c formatter for the
/// subscription period and price texts.
- (instancetype)initWithBottomGradientColors:(NSArray<UIColor *> *)bottomGradientColors
             highlightedBottomGradientColors:(nullable NSArray<UIColor *> *)highlightedBottomColors
                                   formatter:(SPXSubscriptionButtonFormatter *)formatter
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
