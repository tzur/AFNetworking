// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXPromotion.h"

#import "SPXProductAxis.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXCoupon

- (instancetype)initWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                            benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues {
  if (self = [super init]) {
    _baseProductValues = baseProductValues;
    _benefitValues = benefitValues;
  }
  return self;
}

+ (instancetype)couponWithBaseProductValues:(NSArray<SPXBaseProductAxisValue *> *)baseProductValues
                              benefitValues:(NSArray<SPXBenefitAxisValue *> *)benefitValues {
  return [[SPXCoupon alloc] initWithBaseProductValues:baseProductValues
                                        benefitValues:benefitValues];
}

@end

@implementation SPXPromotion

- (instancetype)initWithName:(NSString *)name coupons:(NSArray<SPXCoupon *> *)coupons
                  expiryDate:(NSDate *)expiryDate {
  if (self = [super init]) {
    _name = name;
    _coupons = coupons;
    _expiryDate = expiryDate;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
