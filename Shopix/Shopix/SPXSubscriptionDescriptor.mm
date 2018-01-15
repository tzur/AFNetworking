// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

#import <Bazaar/BZRProductPriceInfo.h>

#import "BZRBillingPeriod+ProductIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionDescriptor

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier {
  return [self initWithProductIdentifier:productIdentifier discountPercentage:0];
}

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage {
  LTParameterAssert(discountPercentage < 100, @"Subscription's discount must be in range [0, 100) "
                    "got: %lu", (unsigned long)discountPercentage);
  if (self = [super init]) {
    _productIdentifier = [productIdentifier copy];
    _billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:productIdentifier];
  }
  return self;
}

- (void)setPriceInfo:(nullable BZRProductPriceInfo *)priceInfo {
  _priceInfo = priceInfo;

  // \c priceInfo.fullPrice is deprecated and will be removed in the upcoming Bazaar versions.
  // \c discountPercentage should replace \c priceInfo.fullPrice by giving a custom discount and
  // concluding the original full price from \c priceInfo.price.
  if (priceInfo.fullPrice && self.discountPercentage) {
    LogError(@"The subscripton product with the identifier (%@) has a conflict between the given "
             "custom subscription's discount (%f) and its deprecated property fullPrice (%@). "
             "Please don't assign a custom discount to an old-format subscription products.",
             self.productIdentifier, self.discountPercentage, priceInfo.fullPrice);
  }
}

@end

NS_ASSUME_NONNULL_END
