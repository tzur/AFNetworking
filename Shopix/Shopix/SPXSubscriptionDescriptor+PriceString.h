// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

/// Category that adds methods for formatting subscription price and full price strings as defined
/// by the descriptor's \c priceInfo and \c discountPercentage properties.
///
/// @note Subscriptions with billing period unit of weeks or days and \c monthlyFormat set to
/// \c YES will raise \c NSInvalidArgumentException.
@interface SPXSubscriptionDescriptor (PriceString)

/// Returns a localized string that represents the subscription price, as specified by
/// \c priceInfo.price. If \c monthlyFormat is \c YES the price will be divided by the number of
/// months in the entire subscription period. If \c monthlyFormat is \c NO the price string will be
/// the price for the entire subscription period. \c monthlyFormat is ignored if \c billingPeriod is
/// \c nil. Returns \c nil if \c priceInfo is \c nil.
- (nullable NSString *)priceString:(BOOL)monthlyFormat;

/// Returns a localized string that represents the subscription full price, as specified by
/// \c priceInfo.fullPrice or \c discountPercentage if given. If \c monthlyFormat is \c YES,
/// the price will be divided by the number of months in the entire subscription period. If
/// \c monthlyFormat is \c NO the price string will be the price for the entire subscription period.
/// \c monthlyFormat is ignored if \c billingPeriod is \c nil. Returns \c nil if \c priceInfo is \c
/// nil or if it doesn't specify a full price and \c discountPercentage is \c 0.
- (nullable NSString *)fullPriceString:(BOOL)monthlyFormat;

@end

NS_ASSUME_NONNULL_END
