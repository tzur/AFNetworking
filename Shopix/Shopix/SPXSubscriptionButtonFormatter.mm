// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonFormatter.h"

#import <Bazaar/BZRProductPriceInfo.h>
#import <Wireframes/UIFont+Utilities.h>

#import "NSDecimalNumber+Localization.h"
#import "UIFont+Shopix.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@interface SPXSubscriptionButtonFormatter ()

/// Subscription period text color.
@property (readonly, nonatomic) UIColor *periodTextColor;

/// Subscription full price text color.
@property (readonly, nonatomic) UIColor *fullPriceTextColor;

/// Subscription price text color.
@property (readonly, nonatomic) UIColor *priceTextColor;

@end

@implementation SPXSubscriptionButtonFormatter

- (instancetype)initWithPeriodTextColor:(UIColor *)periodTextColor
                         priceTextColor:(UIColor *)priceTextColor
                     fullPriceTextColor:(UIColor *)fullPriceTextColor {
  if (self = [super init]) {
    _periodTextColor = periodTextColor;
    _fullPriceTextColor = fullPriceTextColor;
    _priceTextColor = priceTextColor;
  }
  return self;
}

- (NSAttributedString *)periodTextForSubscription:(NSString *)subscriptionIdentifier
                                    monthlyFormat:(BOOL)monthlyFormat {
  if ([subscriptionIdentifier containsString:@".Monthly"]) {
    return [self periodTextForMonths:1];
  } else if ([subscriptionIdentifier containsString:@".BiYearly"]) {
    return [self periodTextForMonths:6];
  } else if ([subscriptionIdentifier containsString:@".Yearly"]) {
    return monthlyFormat ? [self periodTextForMonths:12] : [self periodTextForYearlySubscription];
  } else if ([subscriptionIdentifier containsString:@".OneTimePayment"]) {
    return [self periodTextForOneTimePayment];
  }
  LTParameterAssert(NO, @"Unknown subscription period in product identifier: %@",
                    subscriptionIdentifier);
}

- (NSAttributedString *)periodTextForMonths:(NSUInteger)numberOfMonths {
  auto month = _LDefault(@"Month", @"Label on a button for purchasing subscription that renews "
                         "every one month");
  auto months = _LDefault(@"Months", @"Label on a button for purchasing subscription that renews "
                          "every x months");
  NSString *periodString = numberOfMonths > 1 ? months : month;
  return [self periodTextWithUnitCount:numberOfMonths periodString:periodString];
}

- (NSAttributedString *)periodTextForYearlySubscription {
  auto year = _LDefault(@"Year", @"Label on a button for purchasing subscription that renews every "
                        "one year");
  return [self periodTextWithUnitCount:1 periodString:year];
}

- (NSAttributedString *)periodTextWithUnitCount:(NSUInteger)unitCount
                                   periodString:(NSString *)periodString {
  auto periodText =
    [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", periodString]
                                    attributes:@{
      NSForegroundColorAttributeName: self.periodTextColor,
      NSFontAttributeName: [UIFont spx_standardFontWithSizeRatio:0.018 minSize:11 maxSize:16]
    }];
  auto unitCountString = [NSString stringWithFormat:@"%lu\n", (unsigned long)unitCount];
  auto unitCountText = [[NSMutableAttributedString alloc]
      initWithString:unitCountString attributes:@{
        NSForegroundColorAttributeName: self.periodTextColor,
        NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.038 minSize:18 maxSize:30
                                                    weight:UIFontWeightBold]
      }];
  [unitCountText appendAttributedString:periodText];

  return unitCountText;
}

- (NSAttributedString *)periodTextForOneTimePayment {
  auto periodString =
      _LDefault(@"One-Time\nPurchase", @"Label on a button for purchasing the product at a "
                "single one-time price, instead of a renewable subscription plan");
  return [[NSAttributedString alloc] initWithString:periodString attributes:@{
    NSForegroundColorAttributeName: self.periodTextColor,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.018 minSize:11 maxSize:16
                                                weight:UIFontWeightBold]
  }];
}

- (NSAttributedString *)priceTextForSubscription:(NSString *)subscriptionIdentifier
                                       priceInfo:(BZRProductPriceInfo *)priceInfo
                                   monthlyFormat:(BOOL)monthlyFormat {
  NSUInteger divisor =
      monthlyFormat ? [self divisorForSubscriptionPeriod:subscriptionIdentifier] : 1;
  NSString *priceString = [priceInfo.price spx_localizedPriceForLocale:priceInfo.localeIdentifier
                                                             dividedBy:divisor];

  BOOL isOneTimePayment = [subscriptionIdentifier containsString:@".OneTimePayment"];
  priceString = (monthlyFormat && !isOneTimePayment) ?
      [self appendPerMonthSuffixToPrice:priceString] : priceString;

  return [[NSAttributedString alloc] initWithString:priceString attributes:@{
    NSForegroundColorAttributeName: self.priceTextColor,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.018 minSize:11 maxSize:16
                                                weight:UIFontWeightBold]
  }];
}

- (NSUInteger)divisorForSubscriptionPeriod:(NSString *)subscriptionIdentifier {
  if ([subscriptionIdentifier containsString:@".Monthly"]) {
    return 1;
  } else if ([subscriptionIdentifier containsString:@".BiYearly"]) {
    return 6;
  } else if ([subscriptionIdentifier containsString:@".Yearly"]) {
    return 12;
  } else if ([subscriptionIdentifier containsString:@".OneTimePayment"]) {
    return 1;
  }

  LTParameterAssert(NO, @"Unknown subscription period in product identifier: %@",
                    subscriptionIdentifier);
}

- (NSString *)appendPerMonthSuffixToPrice:(NSString *)price {
  auto perMonthSuffix = _LDefault(@"/mo", @"Abbreviation of the word month, representing per-month "
                                  "suffix of a price, as in $5/mo - $5 per month. The '/' should "
                                  "remain in the localized version");
  return [NSString stringWithFormat:@"%@%@", price, perMonthSuffix];
}

- (nullable NSAttributedString *)fullPriceTextForSubscription:(NSString *)subscriptionIdentifier
                                                    priceInfo:(BZRProductPriceInfo *)priceInfo
                                                monthlyFormat:(BOOL)monthlyFormat {
  if (!priceInfo.fullPrice) {
    return nil;
  }

  NSUInteger divisor =
      monthlyFormat ? [self divisorForSubscriptionPeriod:subscriptionIdentifier] : 1;
  NSString *fullPriceString =
      [priceInfo.fullPrice spx_localizedPriceForLocale:priceInfo.localeIdentifier
                                             dividedBy:divisor];

  BOOL isOneTimePayment = [subscriptionIdentifier containsString:@".OneTimePayment"];
  fullPriceString = (monthlyFormat && !isOneTimePayment) ?
      [self appendPerMonthSuffixToPrice:fullPriceString] : fullPriceString;

  return [[NSAttributedString alloc] initWithString:fullPriceString attributes:@{
    NSForegroundColorAttributeName: self.fullPriceTextColor,
    NSBaselineOffsetAttributeName: @0,
    NSStrikethroughStyleAttributeName: @1,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.018 minSize:11 maxSize:16
                          weight:UIFontWeightLight].wf_fontWithItalicTrait
  }];
}

- (NSAttributedString *)joinedPriceTextForSubscription:(NSString *)subscriptionIdentifier
                                             priceInfo:(BZRProductPriceInfo *)priceInfo
                                         monthlyFormat:(BOOL)monthlyFormat {
  auto attributedPriceText = [self priceTextForSubscription:subscriptionIdentifier
                                                  priceInfo:priceInfo monthlyFormat:monthlyFormat];
  auto _Nullable attributedFullPriceText =
      [self fullPriceTextForSubscription:subscriptionIdentifier priceInfo:priceInfo
                           monthlyFormat:monthlyFormat];

  if (!attributedFullPriceText) {
    return attributedPriceText;
  }

  auto attributedPriceAndFullPrice = [[NSMutableAttributedString alloc]
                                      initWithAttributedString:attributedFullPriceText];
  [attributedPriceAndFullPrice appendAttributedString:[[NSAttributedString alloc]
                                                       initWithString:@"\n"]];
  [attributedPriceAndFullPrice appendAttributedString:attributedPriceText];
  return attributedPriceAndFullPrice;
}

@end

NS_ASSUME_NONNULL_END
