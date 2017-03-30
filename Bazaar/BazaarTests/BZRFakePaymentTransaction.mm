// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakePaymentTransaction.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakePaymentTransaction

@synthesize payment = _payment;
@synthesize transactionState = _transactionState;
@synthesize downloads = _downloads;
@synthesize error = _error;
@synthesize transactionDate = _transactionDate;
@synthesize transactionIdentifier = _transactionIdentifier;
@synthesize originalTransaction = _originalTransaction;

- (instancetype)init {
  SKProduct *product = OCMClassMock([SKProduct class]);
  OCMStub([product productIdentifier]).andReturn(@"foo");
  return [self initWithPayment:[SKPayment paymentWithProduct:product]];
}

- (instancetype)initWithPayment:(SKPayment *)payment {
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
