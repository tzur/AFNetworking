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
__block NSUInteger gracePeriod;
__block BZRPeriodicReceiptValidatorActivator *activator;
__block NSDate *lastValidationDate;

beforeEach(^{
  receiptValidator = OCMClassMock([BZRExternalTriggerReceiptValidator class]);
  validatorErrorsSubject = [RACSubject subject];
  OCMStub([receiptValidator eventsSignal]).andReturn(validatorErrorsSubject);
  receiptValidationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  gracePeriod = 7;
  activator = OCMPartialMock([[BZRPeriodicReceiptValidatorActivator alloc]
                              initWithReceiptValidator:receiptValidator
                              validationStatusProvider:receiptValidationStatusProvider
                              timeProvider:timeProvider gracePeriod:gracePeriod]);

  lastValidationDate = [NSDate date];
});

context(@"deallocating object", ^{
  it(@"should not contain retain cycle", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;
    LLSignalTestRecorder *recorder;

    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionPeriod(1337);
    BZRStubLastValidationDate(receiptValidationStatusProvider, lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 1337 / 2 + 1, lastValidationDate);

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
           gracePeriod:gracePeriod];
      weakPeriodicValidatorActivator = receiptValidatorActivator;
      recorder = [receiptValidatorActivator.errorEventsSignal testRecorder];
    }

    expect(recorder).to.complete();
    expect(weakPeriodicValidatorActivator).to.beNil();
  });
});

context(@"subscription doesn't exist", ^{
  it(@"should deactivate periodic validator if subscription doesn't exist", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    receiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithExpiry(NO);

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
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
           gracePeriod:gracePeriod];

      weakPeriodicValidatorActivator = receiptValidatorActivator;
      recorder = [receiptValidatorActivator.errorEventsSignal testRecorder];

      NSError *error = [NSError lt_errorWithCode:1337];
      BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                                 eventError:error];
      [validatorErrorsSubject sendNext:errorEvent];
    }

    expect(recorder).will.complete();
    expect(weakPeriodicValidatorActivator).to.beNil();
  });

  it(@"should send validation error event even with late subscription", ^{
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 1, lastValidationDate);
    LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 1337, lastValidationDate);
    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                               eventError:underlyingError];

    [validatorErrorsSubject sendNext:errorEvent];

    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventType.value == BZREventTypeNonCriticalError &&
        event.eventError.code == BZRErrorCodePeriodicReceiptValidationFailed &&
        event.eventError.lt_underlyingError == underlyingError;
    });
  });

  it(@"should send validation error and time provider error events if time provider errs", ^{
    NSError *timeProviderError = [NSError lt_errorWithCode:13371337];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal error:timeProviderError]);
    NSError *periodicValidatorError = [NSError lt_errorWithCode:1337];
    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                               eventError:periodicValidatorError];

    LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];
    [validatorErrorsSubject sendNext:errorEvent];

    expect(recorder).will.sendValuesWithCount(2);
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventType.value == BZREventTypeNonCriticalError &&
        event.eventError == timeProviderError;
    });
    expect(recorder).will.matchValue(1, ^BOOL(BZREvent *event) {
      return event.eventType.value == BZREventTypeNonCriticalError &&
        event.eventError.code == BZRErrorCodePeriodicReceiptValidationFailed &&
        event.eventError.lt_underlyingError == periodicValidatorError;
    });
  });

  it(@"should send error with correct days left and last validation date", ^{
    NSUInteger daysPastLastValidation =
        [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] + 4;
    NSTimeInterval currentTimeOffset =
        [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, currentTimeOffset, lastValidationDate);
    NSInteger expectedSecondsLeft =
        [BZRTimeConversion numberOfSecondsInDays:gracePeriod - daysPastLastValidation] +
        activator.periodicValidationInterval;

    NSError *underlyingError = [NSError lt_errorWithCode:1337];
    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                               eventError:underlyingError];

    LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];
    [validatorErrorsSubject sendNext:errorEvent];

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
    NSTimeInterval currentTimeOffset =
        [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, currentTimeOffset, lastValidationDate);

    [activator.errorEventsSignal subscribeNext:^(id) {}];

    NSError *error = [NSError lt_errorWithCode:1337];
    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                               eventError:error];
    [validatorErrorsSubject sendNext:errorEvent];

    expect(receiptValidationStatusProvider.wasExpireSubscriptionCalled).to.beFalsy();
  });

  it(@"should expire subscription if grace period is over", ^{
    NSUInteger daysPastLastValidation =
        [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] +
        gracePeriod + 1;
    NSTimeInterval currentTimeOffset =
        [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, currentTimeOffset, lastValidationDate);

    [activator.errorEventsSignal subscribeNext:^(id) {}];
    NSError *error = [NSError lt_errorWithCode:1337];
    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                               eventError:error];
    [validatorErrorsSubject sendNext:errorEvent];

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
      NSUInteger daysPastLastValidation =
          [BZRTimeConversion numberOfDaysInSeconds:activator.periodicValidationInterval] + 4;
      NSTimeInterval currentTimeOffset =
          [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
      BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, currentTimeOffset, lastValidationDate);
      NSInteger expectedSecondsLeft =
          activator.periodicValidationInterval -
          [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
      NSError *underlyingError = [NSError lt_errorWithCode:1337];
      BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                                 eventError:underlyingError];

      LLSignalTestRecorder *recorder = [[activator errorEventsSignal] testRecorder];
      [validatorErrorsSubject sendNext:errorEvent];

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
      NSTimeInterval currentTimeOffset =
          [BZRTimeConversion numberOfSecondsInDays:daysPastLastValidation];
      BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, currentTimeOffset, lastValidationDate);
      NSError *error = [NSError lt_errorWithCode:1337];
      BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError)
                                                 eventError:error];

      LLSignalTestRecorder *recorder = [activator.errorEventsSignal testRecorder];
      [validatorErrorsSubject sendNext:errorEvent];

      expect(recorder).will.sendValuesWithCount(1);
      expect(receiptValidationStatusProvider.wasExpireSubscriptionCalled).to.beTruthy();
    });
  });
});

SpecEnd
