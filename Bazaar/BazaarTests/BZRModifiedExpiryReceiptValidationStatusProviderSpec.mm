// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRModifiedExpiryReceiptValidationStatusProvider.h"

#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"

SpecBegin(BZRModifiedExpiryReceiptValidationStatusProvider)

__block id<BZRTimeProvider> timeProvider;
__block NSUInteger gracePeriod;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingNonCriticalErrorsSubject;
__block BZRModifiedExpiryReceiptValidationStatusProvider *modifiedReceiptProvider;

beforeEach(^{
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  gracePeriod = 7;
  underlyingProvider =
      OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingNonCriticalErrorsSubject = [RACSubject subject];
  OCMStub([underlyingProvider nonCriticalErrorsSignal])
      .andReturn(underlyingNonCriticalErrorsSubject);
  modifiedReceiptProvider =
      [[BZRModifiedExpiryReceiptValidationStatusProvider alloc] initWithTimeProvider:timeProvider
       expiredSubscriptionGracePeriod:gracePeriod underlyingProvider:underlyingProvider];
});

context(@"deallocating object", ^{
  it(@"should complete when object is deallocated", ^{
    BZRModifiedExpiryReceiptValidationStatusProvider __weak *weakModifiedReceiptProvider;
    RACSignal *fetchSignal;
    RACSignal *errorsSignal;

    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate distantPast]]);
    BZRReceiptValidationStatus *receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    @autoreleasepool {
      BZRModifiedExpiryReceiptValidationStatusProvider *modifiedReceiptProvider =
          [[BZRModifiedExpiryReceiptValidationStatusProvider alloc]
           initWithTimeProvider:timeProvider expiredSubscriptionGracePeriod:gracePeriod
           underlyingProvider:underlyingProvider];

      weakModifiedReceiptProvider = modifiedReceiptProvider;
      fetchSignal = [modifiedReceiptProvider fetchReceiptValidationStatus];
      errorsSignal = [modifiedReceiptProvider nonCriticalErrorsSignal];
    }

    expect(fetchSignal).will.complete();
    expect(errorsSignal).will.complete();
    expect(weakModifiedReceiptProvider).to.beNil();
  });
});

context(@"handling errors", ^{
  it(@"should send non critical error sent by underlying receipt validation status provider", ^{
    LLSignalTestRecorder *recorder = [modifiedReceiptProvider.nonCriticalErrorsSignal testRecorder];

    NSError *error = OCMClassMock([NSError class]);
    [underlyingNonCriticalErrorsSubject sendNext:error];

    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should err when underlying receipt validitation status provider errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder =
        [[modifiedReceiptProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).will.sendError(error);
  });

  context(@"time provider errs", ^{
    __block NSError *error;
    __block BZRReceiptValidationStatus *receiptValidationStatus;

    beforeEach(^{
      error = OCMClassMock([NSError class]);
      OCMStub([timeProvider currentTime]).andReturn([RACSignal error:error]);
      receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
      OCMStub([underlyingProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal return:receiptValidationStatus]);
    });

    it(@"should treat time provider errors as non critical errors", ^{
      LLSignalTestRecorder *recorder =
          [modifiedReceiptProvider.nonCriticalErrorsSignal testRecorder];
      expect([modifiedReceiptProvider fetchReceiptValidationStatus]).will.complete();
      expect(recorder).will.sendValues(@[error]);
    });

    it(@"should provide the underlying provider receipt validation status", ^{
      expect([modifiedReceiptProvider fetchReceiptValidationStatus]).will
          .sendValues(@[receiptValidationStatus]);
    });
  });
});

context(@"receipt validation status without subscription", ^{
  it(@"should return receipt validation status sent by underlying provider", ^{
    BZRReceiptInfo *receipt = [BZRReceiptInfo modelWithDictionary:@{
      @instanceKeypath(BZRReceiptInfo, environment): $(BZRReceiptEnvironmentSandbox),
    } error:nil];
    BZRReceiptValidationStatus *receiptValidationStatus =
        [BZRReceiptValidationStatus modelWithDictionary:@{
          @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
          @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
          @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
        } error:nil];

    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate distantPast]]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    expect([modifiedReceiptProvider fetchReceiptValidationStatus]).will
        .sendValues(@[receiptValidationStatus]);
  });
});


/// Shared examples for modified expiry receipt validation status provider.
static NSString * const kModifiedExpiryProviderExamples = @"modifiedExpiryProviderExamples";

/// Key to the receipt validation status.
static NSString * const kModifiedExpiryProviderReceiptValidationStatusKey =
    @"modifiedExpiryProviderReceiptValidationStatus";

/// Key to the current time.
static NSString * const kModifiedExpiryProviderCurrentTimeKey =
    @"modifiedExpiryProviderCurrentTime";

/// Key to the \c BOOL value that determines whether the subscription's \c isExpired flag should be
/// \c YES or \c NO.
static NSString * const kModifiedExpiryProviderExpectedIsExpiredValueKey =
    @"kModifiedExpiryProviderExpectedIsExpiredValue";

sharedExamplesFor(kModifiedExpiryProviderExamples, ^(NSDictionary *data) {
  __block NSNumber *expectedIsExpired;

  beforeEach(^{
    BZRReceiptValidationStatus *receiptValidationStatus =
        data[kModifiedExpiryProviderReceiptValidationStatusKey];
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    NSDate *currentTime = data[kModifiedExpiryProviderCurrentTimeKey];
    OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
    expectedIsExpired = data[kModifiedExpiryProviderExpectedIsExpiredValueKey];
  });

  it(@"should be equal to received expiry after modifier call", ^{
    LLSignalTestRecorder *recorder =
        [[modifiedReceiptProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).will
        .matchValue(0, ^BOOL(BZRReceiptValidationStatus *receiptValidationStatus) {
          return receiptValidationStatus.receipt.subscription.isExpired ==
              [expectedIsExpired boolValue];
    });
  });
});

context(@"expiry modification", ^{
  __block NSTimeInterval gracePeriodSeconds;
  __block NSDate *gracePeriodNotPassedTime;
  __block NSDate *gracePeriodPassedTime;
  __block BZRReceiptValidationStatus *expiredValidationStatus;
  __block BZRReceiptValidationStatus *notExpiredValidationStatus;
  __block BZRReceiptValidationStatus *cancelledValidationStatus;

  beforeEach(^{
    gracePeriodSeconds = [BZRTimeConversion numberOfSecondsInDays:gracePeriod];
    notExpiredValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    expiredValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    cancelledValidationStatus = BZRReceiptValidationStatusWithExpiry(NO, YES);

    gracePeriodNotPassedTime =
        [notExpiredValidationStatus.receipt.subscription.expirationDateTime
         dateByAddingTimeInterval:(gracePeriodSeconds - 1)];
    gracePeriodPassedTime =
          [expiredValidationStatus.receipt.subscription.expirationDateTime
           dateByAddingTimeInterval:(gracePeriodSeconds + 1)];
  });


  context(@"subscription not expired and grace period is not over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: notExpiredValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodNotPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @NO
      };
    });
  });

  context(@"subscription not expired and grace period is over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: notExpiredValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
      };
    });
  });

  context(@"subscription expired and grace period is not over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: expiredValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodNotPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @NO
      };
    });
  });

  context(@"subscription expired and grace period is over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: expiredValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
      };
    });
  });

  context(@"subscription cancelled and grace period is not over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: cancelledValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodNotPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
      };
    });
  });

  context(@"subscription cancelled and grace period is over", ^{
    itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
      return @{
        kModifiedExpiryProviderReceiptValidationStatusKey: cancelledValidationStatus,
        kModifiedExpiryProviderCurrentTimeKey: gracePeriodPassedTime,
        kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
      };
    });
  });

  context(@"sandbox environment", ^{
    beforeEach(^{
      BZRReceiptInfo *receipt =
          [expiredValidationStatus.receipt
           modelByOverridingProperty:@instanceKeypath(BZRReceiptInfo, environment)
           withValue:$(BZRReceiptEnvironmentSandbox)];
      expiredValidationStatus =
          [expiredValidationStatus
           modelByOverridingProperty:@instanceKeypath(BZRReceiptValidationStatus, receipt)
           withValue:receipt];
      notExpiredValidationStatus =
          [notExpiredValidationStatus
           modelByOverridingProperty:@instanceKeypath(BZRReceiptValidationStatus, receipt)
           withValue:receipt];
    });

    context(@"subscription expired and grace period is not over", ^{
      itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
        return @{
          kModifiedExpiryProviderReceiptValidationStatusKey: expiredValidationStatus,
          kModifiedExpiryProviderCurrentTimeKey: gracePeriodNotPassedTime,
          kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
        };
      });
    });

    context(@"subscription not expired and grace period is not over", ^{
      itShouldBehaveLike(kModifiedExpiryProviderExamples, ^{
        return @{
          kModifiedExpiryProviderReceiptValidationStatusKey: notExpiredValidationStatus,
          kModifiedExpiryProviderCurrentTimeKey: gracePeriodNotPassedTime,
          kModifiedExpiryProviderExpectedIsExpiredValueKey: @YES
        };
      });
    });
  });
});

SpecEnd
