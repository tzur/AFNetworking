// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProductEligibilityVerifier.h"

#import "BZRProduct.h"
#import "BZRReceiptModel+ProductPurchased.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRProductEligibilityVerifier)

/// Shared examples for verifying the correctness of eligibility with reading the receipt validation
/// status.
NSString * const kEligibilityVerifierExamples = @"BZREligibilityVerifierSharedExamples";

/// Key to the value used to determine whether the receipt validation status should be taken from
/// the property or by validating the receipt.
NSString * const kEligibilityVerifierTakeReceiptValidationStatusFromPropertyKey =
    @"eligibilityVerifierTakeReceiptValidationStatusFromProperty";

sharedExamplesFor(kEligibilityVerifierExamples, ^(NSDictionary *data) {
  __block NSString *productIdentifier;
  __block NSUInteger expiredSubscriptionGracePeriod;
  __block id<BZRTimeProvider> timeProvider;
  __block BZRReceiptValidationStatusProvider *receiptValidationStatusProvider;
  __block BZRProductEligibilityVerifier *eligibilityVerifier;
  __block BZRReceiptValidationStatus *receiptValidationStatus;
  __block BZRReceiptInfo *receipt;
  __block BZRReceiptSubscriptionInfo *subscription;

  beforeEach(^{
    productIdentifier = @"foo";
    expiredSubscriptionGracePeriod = 7;
    timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
    receiptValidationStatusProvider = OCMClassMock([BZRReceiptValidationStatusProvider class]);

    eligibilityVerifier = [[BZRProductEligibilityVerifier alloc]
        initWithReceiptValidationStatusProvider:receiptValidationStatusProvider
        timeProvider:timeProvider expiredSubscriptionGracePeriod:expiredSubscriptionGracePeriod];

    receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    receipt = OCMClassMock([BZRReceiptInfo class]);
    subscription = OCMClassMock([BZRReceiptSubscriptionInfo class]);
    if (data[kEligibilityVerifierTakeReceiptValidationStatusFromPropertyKey]) {
      OCMStub([receiptValidationStatusProvider receiptValidationStatus])
          .andReturn(receiptValidationStatus);
    } else {
      OCMStub([receiptValidationStatusProvider validateReceipt])
          .andReturn(receiptValidationStatus);
    }
    OCMStub([receiptValidationStatus receipt]).andReturn(receipt);
  });

  it(@"should send YES when subscription is not expired", ^{
    OCMStub([subscription isExpired]).andReturn(NO);
    OCMStub([receipt subscription]).andReturn(subscription);

    LLSignalTestRecorder *recorder =
        [[eligibilityVerifier verifyEligibilityForProduct:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@YES]);
  });

  it(@"should send YES when subscription expired and grace period is not over", ^{
    OCMStub([subscription isExpired]).andReturn(YES);
    OCMStub([receipt subscription]).andReturn(subscription);
    NSDate *currentTime = [NSDate date];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
    NSDate *expirationTime = [currentTime dateByAddingTimeInterval:
        (-[BZRTimeConversion numberOfSecondsInDays:expiredSubscriptionGracePeriod] + 1337)];
    OCMStub([subscription expirationDateTime]).andReturn(expirationTime);

    LLSignalTestRecorder *recorder =
        [[eligibilityVerifier verifyEligibilityForProduct:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@YES]);
  });

  it(@"should send YES for purchased product", ^{
    BZRReceiptInAppPurchaseInfo *purchaseInfo = OCMClassMock([BZRReceiptInAppPurchaseInfo class]);
    OCMStub([purchaseInfo productId]).andReturn(productIdentifier);
    OCMStub([receipt wasProductPurchased:OCMOCK_ANY]).andReturn(YES);

    LLSignalTestRecorder *recorder =
        [[eligibilityVerifier verifyEligibilityForProduct:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@YES]);
  });

  it(@"should send NO when subscription doesn't exist and product wasn't purchased", ^{
    LLSignalTestRecorder *recorder =
        [[eligibilityVerifier verifyEligibilityForProduct:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@NO]);
  });

  it(@"should send NO when subscription is expired, grace period is over and product wasn't "
     "purchased", ^{
    OCMStub([subscription isExpired]).andReturn(YES);
    OCMStub([subscription expirationDateTime]).andReturn([NSDate distantPast]);
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate distantFuture]]);
    OCMStub([receipt subscription]).andReturn(subscription);

    LLSignalTestRecorder *recorder =
        [[eligibilityVerifier verifyEligibilityForProduct:productIdentifier] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@NO]);
  });
});

context(@"receipt validation status property exists", ^{
  itShouldBehaveLike(kEligibilityVerifierExamples, @{
    kEligibilityVerifierTakeReceiptValidationStatusFromPropertyKey: @YES
  });
});

context(@"receipt validation status property doesn't exist", ^{
  itShouldBehaveLike(kEligibilityVerifierExamples, @{
    kEligibilityVerifierTakeReceiptValidationStatusFromPropertyKey: @NO
  });

  it(@"should err when failed to fetch receipt validation status", ^{
    BZRReceiptValidationStatusProvider *receiptValidationStatusProvider =
        OCMClassMock([BZRReceiptValidationStatusProvider class]);
    id<BZRTimeProvider> timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
    BZRProductEligibilityVerifier *eligibilityVerifier = [[BZRProductEligibilityVerifier alloc]
        initWithReceiptValidationStatusProvider:receiptValidationStatusProvider
        timeProvider:timeProvider expiredSubscriptionGracePeriod:1];
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([receiptValidationStatusProvider validateReceipt]).andReturn([RACSignal error:error]);

    RACSignal *signal = [eligibilityVerifier verifyEligibilityForProduct:@"foo"];

    expect(signal).will.sendError(error);
  });
});

SpecEnd
