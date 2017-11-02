// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

NS_ASSUME_NONNULL_BEGIN

/// Adds convenience methods for getting a localized price given a locale identifier.
@interface NSDecimalNumber (Localization)

/// Returns the localized price of the price specified by the receiver and \c localeIdentifier. The
/// decimal places from the third onwards are trimmed.
- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier;

/// Returns the localized price specified by the receiver divided by \c divisor. The price is
/// localized according to \c localeIdentifier. The decimal places from the third onwards are
/// trimmed. An \c NSInvalidArgumentException is raised if \c divisor is \c 0.
- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier
                                dividedBy:(NSUInteger)divisor;

@end

NS_ASSUME_NONNULL_END
