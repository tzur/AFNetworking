// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPurchaseHelper.h"

#import "BZRMultiAppReceiptValidationStatusProvider.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"

SpecBegin(BZRPurchaseHelper)

__block BZRMultiAppReceiptValidationStatusProvider *multiAppReceiptValidationStatusProvider;
__block BZRPurchaseHelper *purchaseHelper;
__block SKPayment *payment;

beforeEach(^{
  multiAppReceiptValidationStatusProvider =
      OCMClassMock([BZRMultiAppReceiptValidationStatusProvider class]);
  purchaseHelper = [[BZRPurchaseHelper alloc] init];
  purchaseHelper.multiAppReceiptValidationStatusProvider = multiAppReceiptValidationStatusProvider;
  payment = OCMClassMock([SKPayment class]);
});

it(@"should return NO if subscription doesn't exist", ^{
  auto receiptValidationStatus = [BZRReceiptValidationStatusWithExpiry(NO)
      modelByOverridingPropertyAtKeypath:
      @instanceKeypath(BZRReceiptValidationStatus, receipt.subscription)
      withValue:nil];
  OCMStub([multiAppReceiptValidationStatusProvider aggregatedReceiptValidationStatus])
      .andReturn(receiptValidationStatus);

  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beTruthy();
});

it(@"should return NO if subscription is not active", ^{
  OCMStub([multiAppReceiptValidationStatusProvider aggregatedReceiptValidationStatus])
      .andReturn(BZRReceiptValidationStatusWithExpiry(YES));
  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beTruthy();
});

it(@"should return YES if subscription is active", ^{
  OCMStub([multiAppReceiptValidationStatusProvider aggregatedReceiptValidationStatus])
      .andReturn(BZRReceiptValidationStatusWithExpiry(NO));
  expect([purchaseHelper shouldProceedWithPurchase:payment]).to.beFalsy();
});

SpecEnd
