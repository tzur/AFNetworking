// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRSubscriptionIntroductoryDiscount.h"

#import "BZRBillingPeriod.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRIntroductoryDiscountType
#pragma mark -

LTEnumImplement(NSUInteger, BZRIntroductoryDiscountType,
  BZRIntroductoryDiscountTypePayAsYouGo,
  BZRIntroductoryDiscountTypePayUpFront,
  BZRIntroductoryDiscountTypeFreeTrial
);

#pragma mark -
#pragma mark BZRSubscriptionIntroductoryDiscount
#pragma mark -

@implementation BZRSubscriptionIntroductoryDiscount

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, discountType): @"discountType",
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, price): @"price",
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, billingPeriod): @"billingPeriod",
    @instanceKeypath(BZRSubscriptionIntroductoryDiscount, numberOfPeriods): @"numberOfPeriods"
  };
}

+ (NSSet<NSString *> *)optionalPropertyKeys {
  return [NSSet setWithObject:@instanceKeypath(BZRSubscriptionIntroductoryDiscount, price)];
}

+ (NSValueTransformer *)discountTypeJSONTransformer {
  return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:@{
    @"payAsYouGo": $(BZRIntroductoryDiscountTypePayAsYouGo),
    @"payUpFront": $(BZRIntroductoryDiscountTypePayUpFront),
    @"freeTrial": $(BZRIntroductoryDiscountTypeFreeTrial)
  }];
}

+ (NSValueTransformer *)billingPeriodJSONTransformer {
  return [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:[BZRBillingPeriod class]];
}

- (BZRBillingPeriod *)duration {
  return lt::nn([[BZRBillingPeriod alloc] initWithDictionary:@{
    @keypath(self.billingPeriod, unit): self.billingPeriod.unit,
    @keypath(self.billingPeriod, unitCount): @(self.numberOfPeriods * self.billingPeriod.unitCount)
  } error:nil]);
}

@end

NS_ASSUME_NONNULL_END
