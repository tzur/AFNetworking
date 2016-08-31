// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakePaymentTransaction.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakePaymentTransaction

@synthesize payment = _payment;
@synthesize transactionState = _transactionState;
@synthesize downloads = _downloads;

- (instancetype)init {
  return [self initWithPayment:nil];
}

- (instancetype)initWithPayment:(nullable SKPayment *)payment {
  if (self = [super init]) {
    _payment = payment;
    _downloads = @[];
  }
  return self;
}

- (id)copyWithZone:(NSZone __unused * _Nullable)zone {
  BZRFakePaymentTransaction *transaction =
      [[BZRFakePaymentTransaction alloc] initWithPayment:self.payment];
  transaction.transactionState = self.transactionState;
  return transaction;
}

- (BOOL)isEqual:(BZRFakePaymentTransaction *)otherTransaction {
  return ([self.payment isEqual:otherTransaction.payment]
      && self.transactionState == otherTransaction.transactionState);
}

@end

NS_ASSUME_NONNULL_END
