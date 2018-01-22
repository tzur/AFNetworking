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
/// trimmed. An \c NSDecimalNumberDivideByZeroException is raised if \c divisor is \c 0.
- (NSString *)spx_localizedPriceForLocale:(NSString *)localeIdentifier
                                dividedBy:(NSUInteger)divisor;

/// Returns the localized full price of the receiver.
///
/// Returns a localized price which is calculated from the receiver according to the given
/// \c discountPercentage, that should be in the range <tt>[0, 100)</tt>. The price is then divided
/// by \c divisor and rounded up. Finally, if the price before the rounding up wasn't an integer,
/// it will be decreased by a small fraction so it will end with '.99'. The price is localized
/// according to \c localeIdentifier. The decimal places from the third onwards are trimmed. An
/// \c NSDecimalNumberDivideByZeroException is raised if \c divisor is \c 0. An
/// \c NSInvalidArgumentException is raised if \c discountPercentage is greater than \c 100.
///
/// Examples:
/// - For decimal number \c 4.5,
///   <tt>[number spx_localizedFullPriceForLocale:@"en_US" discountPercentage:0 divisor:1]</tt>
///   will return \c "$4.99".
/// - For decimal number \c 4.0,
///   <tt>[number spx_localizedFullPriceForLocale:@"en_US" discountPercentage:0 divisor:2]</tt>
///   will return \c "$2.00".
/// - For decimal number \c 3.99,
///   <tt>[number spx_localizedFullPriceForLocale:@"en_US" discountPercentage:50 divisor:1]</tt>
///   will return \c "$7.99".
- (NSString *)spx_localizedFullPriceForLocale:(NSString *)localeIdentifier
                           discountPercentage:(NSUInteger)discountPercentage
                                    dividedBy:(NSUInteger)divisor;

@end

NS_ASSUME_NONNULL_END
