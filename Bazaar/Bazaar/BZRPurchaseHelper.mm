// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPurchaseHelper.h"

#import "BZRMultiAppReceiptValidationStatusProvider.h"
#import "BZRReceiptModel+HelperProperties.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRPurchaseHelper

- (BOOL)shouldProceedWithPurchase:(SKPayment __unused *)payment {
  return !self.multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus.receipt
      .subscription.isActive;
}

@end

NS_ASSUME_NONNULL_END
