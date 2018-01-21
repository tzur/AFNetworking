// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPurchaseHelper.h"

#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptModel+HelperProperties.h"
#import "BZRReceiptValidationStatus.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRPurchaseHelper ()

/// Provider that provides the latest receipt validation status.
@property (readonly, nonatomic) BZRAggregatedReceiptValidationStatusProvider *
    aggregatedReceiptProvider;

@end

@implementation BZRPurchaseHelper

- (instancetype)initWithAggregatedReceiptProvider:
    (BZRAggregatedReceiptValidationStatusProvider *)aggregatedReceiptProvider {
  if (self = [super init]) {
    _aggregatedReceiptProvider = aggregatedReceiptProvider;
  }
  return self;
}

- (BOOL)shouldProceedWithPurchase:(SKPayment __unused *)payment {
  return !self.aggregatedReceiptProvider.receiptValidationStatus.receipt.subscription.isActive;
}

@end

NS_ASSUME_NONNULL_END
