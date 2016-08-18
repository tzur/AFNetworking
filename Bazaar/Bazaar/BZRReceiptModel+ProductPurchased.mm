// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptModel+ProductPurchased.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptInfo (ProductPurchased)

- (BOOL)wasProductPurchased:(NSString *)productIdentifier {
  for (BZRReceiptInAppPurchaseInfo *purchaseInfo in self.inAppPurchases) {
    if ([purchaseInfo.productId isEqualToString:productIdentifier]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
