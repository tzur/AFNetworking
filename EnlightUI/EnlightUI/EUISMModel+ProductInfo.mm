// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+ProductInfo.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRReceiptModel.h>
#import <LTKit/NSArray+Functional.h>

NS_ASSUME_NONNULL_BEGIN

@implementation EUISMModel (ProductInfo)

- (nullable EUISMProductInfo *)currentProductInfo {
  if (!self.currentSubscriptionInfo) {
    return nil;
  }

  if (self.currentSubscriptionInfo.pendingRenewalInfo.expectedRenewalProductId) {
    auto productId = nn(self.currentSubscriptionInfo.pendingRenewalInfo.expectedRenewalProductId);
    return self.subscriptionGroupProductsInfo[productId];
  }
  return self.subscriptionGroupProductsInfo[nn(self.currentSubscriptionInfo).productId];
}

- (nullable EUISMProductInfo *)promotedProductInfo {
  auto _Nullable currentProductInfo = [self currentProductInfo];
  if (currentProductInfo.product.billingPeriod.unit.value != BZRBillingPeriodUnitMonths) {
    return nil;
  }

  return [self.subscriptionGroupProductsInfo.allValues lt_find:^BOOL(EUISMProductInfo *productInfo)
  {
    auto _Nullable billingPeriod = productInfo.product.billingPeriod;
    return billingPeriod && billingPeriod.unit.value == BZRBillingPeriodUnitYears;
  }];
}

@end

NS_ASSUME_NONNULL_END
