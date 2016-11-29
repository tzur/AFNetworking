// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZREvent.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRPeriodicReceiptValidator.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSError+Bazaar.h"

static void BZRStubLastValidationDate(
    BZRFakeCachedReceiptValidationStatusProvider *receiptValidationStatusProvider,
    NSDate *lastValidationDate) {
  receiptValidationStatusProvider.lastReceiptValidationDate = lastValidationDate;
}

static void BZRStubCurrentTimeOnce(id<BZRTimeProvider> timeProvider, NSDate *lastValidationDate,
                                   NSTimeInterval secondsSinceLastValidationDateDelta) {
  NSDate *currentTime =
      [lastValidationDate dateByAddingTimeInterval:secondsSinceLastValidationDateDelta];
  OCMExpect([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
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

__block BZRPeriodicReceiptValidator *periodicReceiptValidator;
__block RACSubject *periodicValidatorErrorsSubject;
__block BZRFakeCachedReceiptValidationStatusProvider *receiptValidationStatusProvider;
__block id<BZRTimeProvider> timeProvider;
__block NSUInteger gracePeriod;
__block BZRPeriodicReceiptValidatorActivator *activator;
__block NSDate *lastValidationDate;

beforeEach(^{
  periodicReceiptValidator = OCMClassMock([BZRPeriodicReceiptValidator class]);
  periodicValidatorErrorsSubject = [RACSubject subject];
  OCMStub([periodicReceiptValidator errorsSignal]).andReturn(periodicValidatorErrorsSubject);
  receiptValidationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  gracePeriod = 7;
  activator =
      OCMPartialMock([[BZRPeriodicReceiptValidatorActivator alloc]
       initWithPeriodicReceiptValidator:periodicReceiptValidator
       validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
       gracePeriod:gracePeriod]);

  lastValidationDate = [NSDate date];
});

context(@"deallocating object", ^{
  it(@"should not contain retain cycle", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;
    LLSignalTestRecorder *recorder;

    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionPeriod(1337);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, 1337 / 2 + 1);

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *periodicReceiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithPeriodicReceiptValidator:periodicReceiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
           gracePeriod:gracePeriod];
      weakPeriodicValidatorActivator = periodicReceiptValidatorActivator;
      recorder = [periodicReceiptValidatorActivator.errorEventsSignal testRecorder];
    }

    expect(recorder).to.complete();
    expect(weakPeriodicValidatorActivator).to.beNil();
  });
});

context(@"subscription doesn't exist", ^{
  it(@"should deactivate periodic validator if subscription doesn't exist", ^{
    OCMReject([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);
    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(NO);

    OCMVerify([periodicReceiptValidator deactivatePeriodicValidationCheck]);
  });

  it(@"should deactivate periodic validator if receipt validation status is nil", ^{
    OCMReject([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);

    receiptValidationStatusProvider.receiptValidationStatus = nil;

    OCMVerify([periodicReceiptValidator deactivatePeriodicValidationCheck]);
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
    OCMReject([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);
    BZRReceiptValidationStatus *validationStatus = BZRReceiptValidationStatusWithExpiry(YES, YES);
    LTAssert([validationStatus.receipt.subscription.expirationDateTime
              compare:validationStatus.validationDateTime] == NSOrderedDescending,
             @"Expected validation status with validation time prior to expiration time");

    receiptValidationStatusProvider.receiptValidationStatus = validationStatus;

    OCMVerify([periodicReceiptValidator deactivatePeriodicValidationCheck]);
  });

  it(@"should deactivate the periodic validator if subscription was marked as expired before last "
     "validation", ^{
    OCMReject([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    NSDate *postExpirationDateTime =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
         dateByAddingTimeInterval:1];

    receiptValidationStatusProvider.receiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingProperty:@keypath(receiptValidationStatus, validationDateTime)
         withValue:postExpirationDateTime];

    OCMVerify([periodicReceiptValidator deactivatePeriodicValidationCheck]);
  });

  it(@"should activate the periodic validator if subscription exists and is not marked as "
     "expired", ^{
    OCMReject([periodicReceiptValidator deactivatePeriodicValidationCheck]);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, activator.periodicValidationInterval);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);
  });

  it(@"should activate the periodic validator if subscription was marked as expired before "
     "expiration", ^{
    OCMReject([periodicReceiptValidator deactivatePeriodicValidationCheck]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, activator.periodicValidationInterval);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY]);
  });

  it(@"should compute time to next validation to be less than zero", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, subscriptionPeriod / 2 + 1);

    OCMExpect([activator timerSignal:
        [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
          return [timeToNextValidation doubleValue] < 0;
    }]]);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
  });

  it(@"should send value immediately if time to next validation has passed", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, subscriptionPeriod / 2 + 1);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validateReceiptSignal).to.sendValuesWithCount(1);
  });

  it(@"should send value immediately if last validation status is nil", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([periodicReceiptValidator activatePeriodicValidationCheck:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, subscriptionPeriod / 2 - 1);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validateReceiptSignal).to.sendValuesWithCount(1);
  });

  it(@"should correctly compute time left to next validation", ^{
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, 133);

    OCMExpect([activator timerSignal:
               [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
      return [timeToNextValidation doubleValue] - (NSTimeInterval)1337 / 2 - 133 == 0;
    }]]);

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
  });

  it(@"should send event when time provider fails", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder = [activator.errorEventsSignal testRecorder];

    receiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          [event.eventError isEqual:error];
    });
  });
});

context(@"periodic receipt validation failed", ^{
  beforeEach(^{
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);

    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(NO);
  });

  it(@"should not contain retain cycle", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;
    LLSignalTestRecorder *recorder;

    NSError *timeError = [NSError lt_errorWithCode:13371337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:timeError]);

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *periodicReceiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithPeriodicReceiptValidator:periodicReceiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
           gracePeriod:gracePeriod];

      weakPeriodicValidatorActivator = periodicReceiptValidatorActivator;
      recorder = [periodicReceiptValidatorActivator.errorEventsSignal testRecorder];

      [periodicValidatorErrorsSubject sendNext:[NSError lt_errorWithCode:1337]];
    }

    expect(recorder).will.complete();
    expect(weakPeriodicValidatorActivator).to.beNil();
  });

  it(@"should send validation error event even with late subscription", ^{
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate, 1337);

    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    [periodicValidatorErrorsSubject sendNext:underlyingError];

    LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];
    expect(recorder).will.sendValuesWithCount(1);
  });

  it(@"should send error event when time provider fails", ^{
    LLSignalTestRecorder *recorder = [activator.errorEventsSignal testRecorder];
    NSError *error = [NSError lt_errorWithCode:13371337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);

    [periodicValidatorErrorsSubject sendNext:[NSError lt_errorWithCode:1337]];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          [event.eventError isEqual:error];
    });
  });

  it(@"should send error with correct days left and last validation date", ^{
    LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];

    NSUInteger daysPastLastValidation =
        [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] + 4;
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate,
                   [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation]);
    NSInteger expectedSecondsLeft =
        [BZRTimeConversion numberOfSecondsInDays:gracePeriod - daysPastLastValidation]
        + activator.periodicValidationInterval;

    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    [periodicValidatorErrorsSubject sendNext:underlyingError];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return error.lt_isLTDomain && error.code == BZRErrorCodePeriodicReceiptValidationFailed &&
          [error.bzr_secondsUntilSubscriptionInvalidation integerValue] == expectedSecondsLeft &&
          [error.bzr_lastReceiptValidationDate isEqualToDate:lastValidationDate] &&
          error.lt_underlyingError == underlyingError &&
          [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
    });
  });

  it(@"should not expire subscription if grace period not over", ^{
    NSUInteger daysPastLastValidation =
        [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] +
        gracePeriod - 1;
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate,
                           [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation]);

    [activator.errorEventsSignal subscribeNext:^(id) {}];

    [periodicValidatorErrorsSubject sendNext:[NSError lt_errorWithCode:1337]];

    expect(receiptValidationStatusProvider.wasExpireSubscriptionCalled).to.beFalsy();
  });

  it(@"should expire subscription if grace period is over", ^{
    NSUInteger daysPastLastValidation =
        [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] +
        gracePeriod + 1;
    BZRStubCurrentTimeOnce(timeProvider, lastValidationDate,
                           [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation]);

    [activator.errorEventsSignal subscribeNext:^(id) {}];

    [periodicValidatorErrorsSubject sendNext:[NSError lt_errorWithCode:1337]];

    expect(receiptValidationStatusProvider.wasExpireSubscriptionCalled).to.beTruthy();
  });

  context(@"sandbox environment", ^{
    beforeEach(^{
      BZRReceiptInfo *receipt =
          [receiptValidationStatusProvider.receiptValidationStatus.receipt
           modelByOverridingProperty:@instanceKeypath(BZRReceiptInfo, environment)
           withValue:$(BZRReceiptEnvironmentSandbox)];
      receiptValidationStatusProvider.receiptValidationStatus =
          [receiptValidationStatusProvider.receiptValidationStatus
           modelByOverridingProperty:@instanceKeypath(BZRReceiptValidationStatus, receipt)
           withValue:receipt];
    });

    it(@"should not count grace period in seconds left to invalidation", ^{
      LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];

      NSUInteger daysPastLastValidation =
          [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] + 4;
      BZRStubCurrentTimeOnce(timeProvider, lastValidationDate,
                     [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation]);
      NSInteger expectedSecondsLeft =
          activator.periodicValidationInterval -
          [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];

      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      [periodicValidatorErrorsSubject sendNext:underlyingError];

      expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
        NSError *error = event.eventError;
        return error.lt_isLTDomain && error.code == BZRErrorCodePeriodicReceiptValidationFailed &&
            [error.bzr_secondsUntilSubscriptionInvalidation integerValue] == expectedSecondsLeft &&
            [error.bzr_lastReceiptValidationDate isEqualToDate:lastValidationDate] &&
            error.lt_underlyingError == underlyingError &&
            [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
      });
    });

    it(@"should expire subscription if days past last validation has passed", ^{
      NSUInteger daysPastLastValidation =
          [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] + 1;
      BZRStubCurrentTimeOnce(timeProvider, lastValidationDate,
                             [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation]);

      [activator.errorEventsSignal subscribeNext:^(id) {}];

      [periodicValidatorErrorsSubject sendNext:[NSError lt_errorWithCode:1337]];

      expect(receiptValidationStatusProvider.wasExpireSubscriptionCalled).to.beTruthy();
    });
  });
});

SpecEnd
