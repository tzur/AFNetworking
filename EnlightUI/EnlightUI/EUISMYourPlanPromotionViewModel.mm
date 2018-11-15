// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanPromotionViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <LTKit/UIColor+Utilities.h>

#import "EUISMModel.h"
#import "EUISMModel+ProductInfo.h"

NS_ASSUME_NONNULL_BEGIN

using namespace eui;

@implementation EUISMYourPlanPromotionViewModel

@synthesize promotionText = _promotionText;
@synthesize promotionTextColor = _promotionTextColor;
@synthesize upgradeButtonColor = _upgradeButtonColor;
@synthesize upgradeSignal = _upgradeSignal;
@synthesize upgradeRequested = _upgradeRequested;

- (instancetype)initWithModelSignal:(RACSignal<EUISMModel *> *)modelSignal {
  if (self = [super init]) {
    RAC(self, promotionText) = [[[[modelSignal
        ignore:nil]
        map:^NSString *(EUISMModel *model) {
          return [EUISMYourPlanPromotionViewModel promotionTextFromModel:model];
        }]
        startWith:@""]
        deliverOnMainThread];

    RAC(self, promotionTextColor) = [[[[modelSignal
        ignore:nil]
        map:^UIColor *(EUISMModel *model) {
          return [EUISMYourPlanPromotionViewModel promotionTextColorFromModel:model];
        }]
        startWith:[UIColor grayColor]]
        deliverOnMainThread];

    RAC(self, upgradeButtonColor) = [[[[modelSignal
        ignore:nil]
        map:^UIColor *(EUISMModel *model) {
          return [EUISMYourPlanPromotionViewModel upgradeButtonColorFromModel:model];
        }]
        startWith:[UIColor grayColor]]
        deliverOnMainThread];

    auto upgradeRequested = [RACObserve(self, upgradeRequested) switchToLatest];
    _upgradeSignal = [[[[[modelSignal replayLast] sample:upgradeRequested]
        ignore:nil]
        map:^EUISMProductInfo * _Nullable(EUISMModel *model) {
          return [model promotedProductInfo];
        }]
        ignore:nil];
  }
  return self;
}

+ (NSString *)promotionTextFromModel:(EUISMModel *)model {
  auto noPromotion = @"";
  auto _Nullable productInfo = [model currentProductInfo];
  auto _Nullable billingPeriod = productInfo.product.billingPeriod;
  auto _Nullable priceInfo = productInfo.product.priceInfo;

  if (!priceInfo || !billingPeriod) {
    return noPromotion;
  }

  EUISMProductInfo * _Nullable promotedProductInfo = [model promotedProductInfo];
  if (!promotedProductInfo || !promotedProductInfo.product.priceInfo) {
    return noPromotion;
  }

  NSDecimalNumber *promotedPrice =
      [EUISMYourPlanPromotionViewModel
       normalizedPriceWithPriceInfo:nn(promotedProductInfo.product.priceInfo)
       billingPeriod:nn(promotedProductInfo.product.billingPeriod)];
  NSDecimalNumber *currentPrice = /* TODO:(Dekel) fix once BZR exposes a more accurate price */
      [EUISMYourPlanPromotionViewModel normalizedPriceWithPriceInfo:nn(priceInfo)
                                                      billingPeriod:nn(billingPeriod)];
  if ([currentPrice compare:promotedPrice] != NSOrderedDescending ||
      [currentPrice isEqualToNumber:[NSDecimalNumber zero]]) {
    return noPromotion;
  }

  auto discount = [currentPrice decimalNumberBySubtracting:promotedPrice];
  auto discountRatio = [discount decimalNumberByDividingBy:currentPrice].doubleValue;
  if (discountRatio <= 0.01) {
    return noPromotion;
  }

  auto save = _LDefault(@"GO YEARLY AND SAVE", @"Text shown as a promotion for yearly "
                        "subscription. The save percent will be added after this text. For "
                        "example: GO YEARLY AND SAVE 50%");
  auto percentFormatter = [[NSNumberFormatter alloc] init];
  percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
  auto percent = [percentFormatter stringFromNumber:@(discountRatio)];
  return [NSString stringWithFormat:@"%@ %@", save, percent];
}

+ (NSDecimalNumber *)normalizedPriceWithPriceInfo:(BZRProductPriceInfo *)priceInfo
                                    billingPeriod:(BZRBillingPeriod *)billingPeriod {
  auto months = [EUISMYourPlanPromotionViewModel monthsInBillingPeriod:billingPeriod];
  if (!months) {
    return [NSDecimalNumber zero];
  }
  auto decimalMonths = [NSDecimalNumber decimalNumberWithDecimal:@(months).decimalValue];
  return [priceInfo.price decimalNumberByDividingBy:decimalMonths];
}

+ (NSUInteger)monthsInBillingPeriod:(BZRBillingPeriod *)billingPeriod {
  NSUInteger result = 0;
  if (billingPeriod.unit.value == BZRBillingPeriodUnitYears) {
    result = billingPeriod.unitCount * 12;
  } else if (billingPeriod.unit.value == BZRBillingPeriodUnitMonths) {
    result = billingPeriod.unitCount;
  }
  return result;
}

+ (UIColor *)promotionTextColorFromModel:(EUISMModel *)model {
  switch (model.currentApplication.value) {
    case EUISMApplicationPhotofox:
      return [UIColor lt_colorWithHex:@"#7F66FF"];
    case EUISMApplicationVideoleap:
      return [UIColor lt_colorWithHex:@"#7F66FF"]; // TODO:(Dekel) get color from Ivan
    case EUISMApplicationQuickshot:
      return [UIColor lt_colorWithHex:@"#7F66FF"]; // TODO:(Dekel) get color from Ivan
    case EUISMApplicationPixaloop:
      return [UIColor lt_colorWithHex:@"#7F66FF"]; // TODO:(Dekel) get color from Ivan
  }
  return [UIColor grayColor];
}

+ (UIColor *)upgradeButtonColorFromModel:(EUISMModel *)model {
  switch (model.currentApplication.value) {
    case EUISMApplicationPhotofox:
      return [UIColor lt_colorWithHex:@"#6B54FF"];
    case EUISMApplicationVideoleap:
      return [UIColor lt_colorWithHex:@"#6B54FF"]; // TODO:(Dekel) get color from Ivan
    case EUISMApplicationQuickshot:
      return [UIColor lt_colorWithHex:@"#6B54FF"]; // TODO:(Dekel) get color from Ivan
    case EUISMApplicationPixaloop:
      return [UIColor lt_colorWithHex:@"#6B54FF"]; // TODO:(Dekel) get color from Ivan
  }
  return [UIColor grayColor];
}

@end

NS_ASSUME_NONNULL_END
