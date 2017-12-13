// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZREvent.h"
#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

static void BZRStubLastValidationDate(
    BZRFakeCachedReceiptValidationStatusProvider *receiptValidationStatusProvider,
    NSDate *lastValidationDate) {
  receiptValidationStatusProvider.lastReceiptValidationDate = lastValidationDate;
}

static void BZRStubCurrentTimeWithIntervalSinceDate(id<BZRTimeProvider> timeProvider,
                                                    NSTimeInterval interval, NSDate *date) {
  OCMStub([timeProvider currentTime])
      .andReturn([RACSignal return:[date dateByAddingTimeInterval:interval]]);
}

static BZRReceiptValidationStatus *BZRReceiptValidationStatusWithSubscriptionPeriod
    (NSTimeInterval subscriptionPeriod) {
  BZRReceiptValidationStatus *receiptValidationStatus =
      OCMClassMock([BZRReceiptValidationStatus class]);
  BZRReceiptInfo *receipt = OCMClassMock([BZRReceiptInfo class]);
  BZRReceiptSubscriptionInfo *subscription = OCMClassMock([BZRReceiptSubscriptionInfo class]);
  OCMStub([receiptValidationStatus receipt]).andReturn(receipt);
  OCMStub([receipt subscription]).andReturn(subscription);
  OCMStub([subscription expirationDateTime])
      .andReturn([[NSDate date] dateByAddingTimeInterval:subscriptionPeriod]);
  OCMStub([subscription originalPurchaseDateTime]).andReturn([NSDate date]);

  return receiptValidationStatus;
}

SpecBegin(BZRPeriodicReceiptValidatorActivator)

__block BZRExternalTriggerReceiptValidator *receiptValidator;
__block RACSubject *validatorErrorsSubject;
__block BZRFakeCachedReceiptValidationStatusProvider *receiptValidationStatusProvider;
__block id<BZRTimeProvider> timeProvider;
__block BZRPeriodicReceiptValidatorActivator *activator;
__block NSDate *lastValidationDate;

beforeEach(^{
  receiptValidator = OCMClassMock([BZRExternalTriggerReceiptValidator class]);
  validatorErrorsSubject = [RACSubject subject];
  OCMStub([receiptValidator eventsSignal]).andReturn(validatorErrorsSubject);
  receiptValidationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  activator = OCMPartialMock([[BZRPeriodicReceiptValidatorActivator alloc]
                              initWithReceiptValidator:receiptValidator
                              validationStatusProvider:receiptValidationStatusProvider
                              timeProvider:timeProvider]);

  lastValidationDate = [NSDate date];
});

context(@"deallocating object", ^{
  it(@"should not contain retain cycle", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;

    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 1337 / 2 + 1, lastValidationDate);
    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionPeriod(1337);

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider];
      weakPeriodicValidatorActivator = receiptValidatorActivator;
    }

    expect(weakPeriodicValidatorActivator).to.beNil();
  });
});

context(@"subscription doesn't exist", ^{
  it(@"should deactivate periodic validator if subscription doesn't exist", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentProduction),
    } error:nil];
    receiptValidationStatusProvider.receiptValidationStatus =
        [BZRReceiptValidationStatus modelWithDictionary:@{
          @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
          @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
          @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
        } error:nil];

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should deactivate periodic validator if receipt validation status is nil", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);

    receiptValidationStatusProvider.receiptValidationStatus = nil;

    OCMVerify([receiptValidator deactivate]);
  });
});

context(@"subscription exists", ^{
  __block NSTimeInterval subscriptionPeriod;
  __block BZRReceiptValidationStatus *receiptValidationStatus;

  beforeEach(^{
    subscriptionPeriod = 1337;
    receiptValidationStatus = BZRReceiptValidationStatusWithSubscriptionPeriod(subscriptionPeriod);
  });

  it(@"should deactivate the periodic validator if subscription is cancelled", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    BZRReceiptValidationStatus *validationStatus = BZRReceiptValidationStatusWithExpiry(YES, YES);
    LTAssert([validationStatus.receipt.subscription.expirationDateTime
              compare:validationStatus.validationDateTime] == NSOrderedDescending,
             @"Expected validation status with validation time prior to expiration time");

    receiptValidationStatusProvider.receiptValidationStatus = validationStatus;

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should deactivate the periodic validator if subscription was marked as expired before last "
     "validation", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    NSDate *postExpirationDateTime =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
         dateByAddingTimeInterval:1];

    receiptValidationStatusProvider.receiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingProperty:@keypath(receiptValidationStatus, validationDateTime)
         withValue:postExpirationDateTime];

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should activate the periodic validator if subscription exists and is not marked as expired",
     ^{
    OCMReject([receiptValidator deactivate]);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, activator.periodicValidationInterval,
                                            lastValidationDate);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([receiptValidator activateWithTrigger:OCMOCK_ANY]);
  });

  it(@"should activate the periodic validator if subscription was marked as expired before "
     "expiration", ^{
    OCMReject([receiptValidator deactivate]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
       BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, activator.periodicValidationInterval,
                                               lastValidationDate);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([receiptValidator activateWithTrigger:OCMOCK_ANY]);
  });

  it(@"should compute time to next validation to be less than zero", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([receiptValidator activateWithTrigger:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, subscriptionPeriod / 2 + 1,
                                            lastValidationDate);

    OCMExpect([activator timerSignal:
        [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
          return [timeToNextValidation doubleValue] < 0;
    }]]);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
  });

  it(@"should send value immediately if time to next validation has passed", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([receiptValidator activateWithTrigger:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, subscriptionPeriod / 2 + 1,
                                            lastValidationDate);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validateReceiptSignal).to.sendValuesWithCount(1);
  });

  it(@"should send value immediately if last validation status is nil", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([receiptValidator activateWithTrigger:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, subscriptionPeriod / 2 - 1,
                                            lastValidationDate);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validateReceiptSignal).to.sendValuesWithCount(1);
  });

  it(@"should correctly compute time left to next validation", ^{
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 133, lastValidationDate);

    OCMExpect([activator timerSignal:
               [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
      return [timeToNextValidation doubleValue] - (NSTimeInterval)1337 / 2 - 133 == 0;
    }]]);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
  });
});

SpecEnd
