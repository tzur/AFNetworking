// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

@class SPXColorScheme, SPXSubscriptionDescriptor, BZRProductPriceInfo;

#pragma mark -
#pragma mark SPXSubscriptionButtonFormatter
#pragma mark -

/// Formatter that receives as input the subscription product information and outputs formatted
/// attributed strings. Font sizes are determined by the screen height.
///
/// @note Subscriptions with billing period unit of weeks or days are not supported, using those
/// subscription will raise \c NSInvalidArgumentException.
@interface SPXSubscriptionButtonFormatter : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c colorScheme for default colors mapping. \c periodTextColor is set to
/// \c darkTextColor \c priceTextColor is set to \c textColor. \c fullPriceTextColor is set to
/// \c grayedTextColor.
- (instancetype)initColorScheme:(SPXColorScheme *)colorScheme;

/// Initializes with the color \c periodTextColor for the subscription period text,
/// \c priceTextColor and \c fullPriceTextColor for the price texts.
- (instancetype)initWithPeriodTextColor:(UIColor *)periodTextColor
                         priceTextColor:(UIColor *)priceTextColor
                     fullPriceTextColor:(UIColor *)fullPriceTextColor NS_DESIGNATED_INITIALIZER;

/// Returns an attributed string that represents the subscription period that is determined by
/// \c descriptor.billingPeriod. If \c monthlyFormat is \c YES the period text will be in months -
/// e.g '12 months for yearly subscription'. otherwise the string will be the most native textual
/// description of the subscription period - e.g '1 Year' for yearly subscription.
- (NSAttributedString *)billingPeriodTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                           monthlyFormat:(BOOL)monthlyFormat;

/// Returns an attributed and localized string that represents the price, as specified by
/// \c priceInfo.price for the subscription product specified by \c descriptor.billingPeriod. If
/// \c monthlyFormat is \c YES the price will be divided by the number of months in the full
/// subscription period and the suffix '/mo' will be appended to the price text. If \c monthlyFormat
/// is \c NO the price text is for the full subscription period. \c monthlyFormat is ignored if
/// subscription period of type one-time payment. \c NSInvalidArgumentException is raised if
/// \c descriptor.priceInfo is \c nil.
- (NSAttributedString *)priceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                   monthlyFormat:(BOOL)monthlyFormat;

/// Returns an attributed and localized string with strike-through that represents the full price,
/// as specified by \c priceInfo.fullPrice for the subscription product specified by
/// \c descriptor.billingPeriod. If \c monthlyFormat is \c YES, the price will be divided by the
/// number of months in the full subscription period and the suffix '/mo' will be appended to the
/// price text. If \c monthlyFormat is \c NO the price text is for the full subscription period.
/// \c monthlyFormat is ignored if subscription period of type one-time payment.
/// Returns \c nil if \c priceInfo doesn't specify a full price. \c NSInvalidArgumentException is
/// raised if \c descriptor.priceInfo is \c nil.
- (nullable NSAttributedString *)
    fullPriceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
    monthlyFormat:(BOOL)monthlyFormat;

/// Returns an attributed and localized string that is the joint of the price text preceded by the
/// full price text for the given parameters. If there is no full price, only the price text is
/// returned.
///
/// @see \c priceTextForSubscription:priceInfo:monthlyFormat:
/// and \c fullPriceTextForSubscription:priceInfo:monthlyFormat:
- (NSAttributedString *)joinedPriceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                         monthlyFormat:(BOOL)monthlyFormat;

@end

NS_ASSUME_NONNULL_END
