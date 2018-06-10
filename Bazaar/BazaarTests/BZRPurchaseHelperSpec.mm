// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPurchaseHelper.h"

#import "BZRAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"

SpecBegin(BZRPurchaseHelper)

__block BZRAggregatedReceiptValidationStatusProvider *aggregatedReceiptProvider;
__block BZRPurchaseHelper *purchaseHelper;
__block SKPayment *payment;

beforeEach(^{
  aggregatedReceiptProvider = OCMClassMock([BZRAggregatedReceiptValidationStatusProvider class]);
  purchaseHelper = [[BZRPurchaseHelper alloc] init];
  purchaseHelper.aggregatedReceiptProvider = aggregatedReceiptProvider;
  payment = OCMClassMock([SKPayment class]);
});

it(@"should return NO if subscription doesn't exist", ^{
  auto receiptValidationStatus = [BZRReceiptValidationStatusWithExpiry(NO)
      modelByOverridingPropertyAtKeypath:
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
      withValue:nil];
  OCMStub([aggregatedReceiptProvider receiptValidationStatus]).andReturn(receiptValidationStatus);

  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beTruthy();
});

it(@"should return NO if subscription is not active", ^{
  OCMStub([aggregatedReceiptProvider receiptValidationStatus])
      .andReturn(BZRReceiptValidationStatusWithExpiry(YES));
  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beTruthy();
});

it(@"should return YES if subscription is active", ^{
  OCMStub([aggregatedReceiptProvider receiptValidationStatus])
      .andReturn(BZRReceiptValidationStatusWithExpiry(NO));
  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beFalsy();
});

SpecEnd
