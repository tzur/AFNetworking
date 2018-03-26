// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTSubscriptionInfo.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, INTSubscriptionStatus,
  INTSubscriptionStatusActive,
  INTSubscriptionStatusCancelled,
  INTSubscriptionStatusExpired
);

@implementation INTSubscriptionInfo

- (instancetype)initWithSubscriptionStatus:(INTSubscriptionStatus *)subscriptionStatus
                                 productID:(NSString *)productID
                             transactionID:(NSString *)transactionID
                              purchaseDate:(NSDate *)purchaseDate
                            expirationDate:(NSDate *)expirationDate
                          cancellationDate:(nullable NSDate *)cancellationDate {
  if (self = [super init]) {
    _subscriptionStatus = subscriptionStatus;
    _productID = productID;
    _transactionID = transactionID;
    _purchaseDate = purchaseDate;
    _expirationDate = expirationDate;
    _cancellationDate = cancellationDate;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
