// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXPurchaseSubscriptionEvent.h"

#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRReceiptModel.h>

#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXPurchaseSubscriptionEvent

- (instancetype)initWithSubscriptionDescriptor:(SPXSubscriptionDescriptor *)subscriptionDescriptor
                            successfulPurchase:(BOOL)successfulPurchase
                                   receiptInfo:(nullable BZRReceiptSubscriptionInfo *)receiptInfo
                              purchaseDuration:(CFTimeInterval)purchaseDuration
                                         error:(nullable NSError *)error {
  if (self = [super init]) {
    _productIdentifier = [subscriptionDescriptor.productIdentifier copy];
    _price = subscriptionDescriptor.priceInfo.price;
    _localeIdentifier = subscriptionDescriptor.priceInfo.localeIdentifier;
    _currencyCode = [NSLocale localeWithLocaleIdentifier:self.localeIdentifier].currencyCode;
    _originalTransactionId = receiptInfo.originalTransactionId;
    _purchaseDuration = purchaseDuration;
    _successfulPurchase = successfulPurchase;
    _failureDescription = error.lt_errorCodeDescription;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
