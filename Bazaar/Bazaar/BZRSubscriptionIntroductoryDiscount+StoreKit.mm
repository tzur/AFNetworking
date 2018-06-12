// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRSubscriptionIntroductoryDiscount+StoreKit.h"

#import "BZRBillingPeriod+StoreKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRSubscriptionIntroductoryDiscount (StoreKit)

+ (nullable instancetype)introductoryDiscountForSKProduct:(SKProduct *)product {
  if (@available(iOS 11.2, *)) {
    return product.introductoryPrice ?
        [self introductoryDiscountWithSKProductDiscount:product.introductoryPrice] : nil;
  }

  return nil;
}

+ (instancetype)introductoryDiscountWithSKProductDiscount:(SKProductDiscount *)discount {
  static NSDictionary * const kSKProductDiscountPaymentModeToBZRIntroductoryDiscountType = @{
    @(SKProductDiscountPaymentModePayAsYouGo): $(BZRIntroductoryDiscountTypePayAsYouGo),
    @(SKProductDiscountPaymentModePayUpFront): $(BZRIntroductoryDiscountTypePayUpFront),
    @(SKProductDiscountPaymentModeFreeTrial): $(BZRIntroductoryDiscountTypeFreeTrial)
  };

  return [[BZRSubscriptionIntroductoryDiscount alloc] initWithDictionary:@{
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, discountType):
        kSKProductDiscountPaymentModeToBZRIntroductoryDiscountType[@(discount.paymentMode)],
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, price): discount.price,
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, billingPeriod):
        [BZRBillingPeriod billingPeriodForSKProductSubscriptionPeriod:discount.subscriptionPeriod],
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, numberOfPeriods):
        @(discount.numberOfPeriods)
  } error:nil];
}

@end

NS_ASSUME_NONNULL_END
