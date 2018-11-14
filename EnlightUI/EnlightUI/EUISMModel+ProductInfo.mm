// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+ProductInfo.h"

#import <Bazaar/BZRReceiptModel.h>

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

@end

NS_ASSUME_NONNULL_END
