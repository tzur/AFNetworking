// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonFormatter.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Wireframes/UIFont+Utilities.h>

#import "NSDecimalNumber+Localization.h"
#import "SPXColorScheme.h"
#import "SPXSubscriptionDescriptor.h"
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

- (instancetype)initColorScheme:(SPXColorScheme *)colorScheme {
    return [self initWithPeriodTextColor:colorScheme.darkTextColor
                          priceTextColor:colorScheme.textColor
                      fullPriceTextColor:colorScheme.grayedTextColor];
}

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

- (NSAttributedString *)billingPeriodTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                           monthlyFormat:(BOOL)monthlyFormat {
  if ([descriptor.billingPeriod.unit isEqual:$(BZRBillingPeriodUnitMonths)]) {
    return [self periodTextForMonths:descriptor.billingPeriod.unitCount];
  } else if ([descriptor.billingPeriod.unit isEqual:$(BZRBillingPeriodUnitYears)]) {
    return monthlyFormat ? [self periodTextForMonths:descriptor.billingPeriod.unitCount * 12] :
        [self periodTextForYearlySubscription];
  } else if (!descriptor.billingPeriod) {
    return [self periodTextForOneTimePayment];
  }

  LTParameterAssert(NO, @"Unsupported subscription's billing period (%@) in subscription with "
                    "product identifier: %@", descriptor.billingPeriod,
                    descriptor.productIdentifier);
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
      NSFontAttributeName: [UIFont spx_standardFontWithSizeRatio:0.016 minSize:11 maxSize:16]
    }];
  auto unitCountString = [NSString stringWithFormat:@"%lu\n", (unsigned long)unitCount];
  auto unitCountText = [[NSMutableAttributedString alloc]
      initWithString:unitCountString attributes:@{
        NSForegroundColorAttributeName: self.periodTextColor,
        NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.036 minSize:18 maxSize:25
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
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.016 minSize:11 maxSize:16
                                                weight:UIFontWeightBold]
  }];
}

- (NSAttributedString *)priceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                   monthlyFormat:(BOOL)monthlyFormat {
  LTParameterAssert(descriptor.priceInfo, @"Price text for the subscription product (%@) is "
                    "requested but the subscription price information is nil",
                    descriptor.productIdentifier);

  NSUInteger divisor = (monthlyFormat && descriptor.billingPeriod) ?
      [self numberOfMonthsInSubscriptionPeriod:descriptor.billingPeriod] : 1;
  NSString *priceString = [descriptor.priceInfo.price
                           spx_localizedPriceForLocale:descriptor.priceInfo.localeIdentifier
                           dividedBy:divisor];
  if (monthlyFormat && descriptor.billingPeriod) {
    priceString = [self appendPerMonthSuffixToPrice:priceString];
  }

  return [[NSAttributedString alloc] initWithString:priceString attributes:@{
    NSForegroundColorAttributeName: self.priceTextColor,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.016 minSize:11 maxSize:16
                                                weight:UIFontWeightBold]
  }];
}

- (NSUInteger)numberOfMonthsInSubscriptionPeriod:(BZRBillingPeriod *)billingPeriod {
  if ([billingPeriod.unit isEqual:$(BZRBillingPeriodUnitMonths)]) {
    return billingPeriod.unitCount;
  } else if ([billingPeriod.unit isEqual:$(BZRBillingPeriodUnitYears)]) {
    return billingPeriod.unitCount * 12;
  }

  LTParameterAssert(NO, @"Unsupported subscription's billing period: %@", billingPeriod);
}

- (NSString *)appendPerMonthSuffixToPrice:(NSString *)price {
  auto perMonthSuffix = _LDefault(@"/mo", @"Abbreviation of the word month, representing per-month "
                                  "suffix of a price, as in $5/mo - $5 per month. The '/' should "
                                  "remain in the localized version");
  return [NSString stringWithFormat:@"%@%@", price, perMonthSuffix];
}

- (BOOL)isMonthlyBillingPeriod:(BZRBillingPeriod *)billingPeriod {
  return [billingPeriod.unit isEqual:$(BZRBillingPeriodUnitMonths)] && billingPeriod.unitCount == 1;
}

- (nullable NSAttributedString *)
    fullPriceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
    monthlyFormat:(BOOL)monthlyFormat {
  LTParameterAssert(descriptor.priceInfo, @"Full price text for the subscription product (%@) is "
                    "requested but the subscription price information is nil",
                    descriptor.productIdentifier);

  if (!descriptor.priceInfo.fullPrice && !descriptor.discountPercentage) {
    return nil;
  }

  NSUInteger divisor = (monthlyFormat && descriptor.billingPeriod) ?
      [self numberOfMonthsInSubscriptionPeriod:descriptor.billingPeriod] : 1;

  NSString *fullPriceString;
  if (descriptor.priceInfo.fullPrice) {
    fullPriceString = [descriptor.priceInfo.fullPrice
                       spx_localizedPriceForLocale:descriptor.priceInfo.localeIdentifier
                       dividedBy:divisor];
  } else if (descriptor.discountPercentage) {
    fullPriceString = [descriptor.priceInfo.price
                       spx_localizedFullPriceForLocale:descriptor.priceInfo.localeIdentifier
                       discountPercentage:descriptor.discountPercentage dividedBy:divisor];
  } else {
    return nil;
  }

  fullPriceString = (monthlyFormat && descriptor.billingPeriod) ?
      [self appendPerMonthSuffixToPrice:fullPriceString] : fullPriceString;

  return [[NSAttributedString alloc] initWithString:fullPriceString attributes:@{
    NSForegroundColorAttributeName: self.fullPriceTextColor,
    NSBaselineOffsetAttributeName: @0,
    NSStrikethroughStyleAttributeName: @1,
    NSFontAttributeName: [UIFont spx_fontWithSizeRatio:0.016 minSize:11 maxSize:16
                          weight:UIFontWeightLight].wf_fontWithItalicTrait
  }];
}

- (NSAttributedString *)joinedPriceTextForSubscription:(SPXSubscriptionDescriptor *)descriptor
                                         monthlyFormat:(BOOL)monthlyFormat {
  auto attributedPriceText = [self priceTextForSubscription:descriptor monthlyFormat:monthlyFormat];
  auto _Nullable attributedFullPriceText =
      [self fullPriceTextForSubscription:descriptor monthlyFormat:monthlyFormat];

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
