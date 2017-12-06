// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXRestorePurchasesEvent.h"

#import <Bazaar/BZRReceiptModel.h>

NS_ASSUME_NONNULL_BEGIN

@implementation SPXRestorePurchasesEvent

- (instancetype)initWithSuccessfulRestore:(BOOL)successfulRestore
                              receiptInfo:(nullable BZRReceiptInfo *)receiptInfo
                          restoreDuration:(CFTimeInterval)restoreDuration
                                    error:(nullable NSError *)error {
  if (self = [super init]) {
    _successfulRestore = successfulRestore;
    _isSubscriber = receiptInfo.subscription && !receiptInfo.subscription.isExpired;
    _originalTransactionId = receiptInfo.subscription.originalTransactionId;
    _restoreDuration = restoreDuration;
    _failureDescription = error.lt_errorCodeDescription;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
