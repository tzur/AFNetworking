// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRFakeAggregatedReceiptValidationStatusProvider.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

// Stubs \c receiptValidationStatusProvider to return the given \c bundleIDToCacheEntries.
static void BZRStubLoadedCacheEntries(
  BZRCachedReceiptValidationStatusProvider *receiptValidationStatusProvider,
  NSDictionary<NSString *, BZRReceiptValidationStatusCacheEntry *> *bundleIDToCacheEntries) {
  OCMStub([receiptValidationStatusProvider
      loadReceiptValidationStatusCacheEntries:OCMOCK_ANY]).andReturn(bundleIDToCacheEntries);
}

// Returns a \c BZRReceiptValidationStatusCacheEntry that contains the given
// \c lastReceiptValidationDate and a receipt validation status with non-expired subscription.
static BZRReceiptValidationStatusCacheEntry *BZRCacheEntryWithActiveSubscriptionAndDate(
    NSDate *lastReceiptValidationDate) {
  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:BZRReceiptValidationStatusWithExpiry(NO)
          cachingDateTime:lastReceiptValidationDate];
}

// Stubs loading cache entries via \c receiptValidationStatusProvider to return a dictionary
// containing bundleID mapped to a cache entry containing the given \c lastReceiptValidationDate.
static void BZRStubLoadedCacheEntryWithLastReceiptValidationDate(
    BZRCachedReceiptValidationStatusProvider *receiptValidationStatusProvider,
    NSString *bundleID, NSDate *lastReceiptValidationDate) {
  auto cacheEntry = BZRCacheEntryWithActiveSubscriptionAndDate(lastReceiptValidationDate);
  BZRStubLoadedCacheEntries(receiptValidationStatusProvider, @{bundleID: cacheEntry});
}

// Stubs \c timeProvider to set the current time to be \c date plus \c interval seconds.
static void BZRStubCurrentTimeWithIntervalSinceDate(id<BZRTimeProvider> timeProvider,
                                                    NSTimeInterval interval, NSDate *date) {
  OCMStub([timeProvider currentTime])
      .andReturn([RACSignal return:[date dateByAddingTimeInterval:interval]]);
}

// Creates a new \c BZRReceiptValidationStatus with a subscription and with \c expirationDateTime
// set to be the current time plus \c subscriptionPeriod.
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
__block BZRCachedReceiptValidationStatusProvider *receiptValidationStatusProvider;
__block id<BZRTimeProvider> timeProvider;
__block BZRFakeAggregatedReceiptValidationStatusProvider *
    aggregatedReceiptValidationStatusProvider;
__block NSString *currentApplicationBundleID;
__block NSSet<NSString *> *bundledApplicationsIDs;
__block BZRPeriodicReceiptValidatorActivator *activator;
__block NSDate *lastValidationDate;

beforeEach(^{
  receiptValidator = OCMClassMock([BZRExternalTriggerReceiptValidator class]);
  receiptValidationStatusProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  currentApplicationBundleID = @"foo";
  bundledApplicationsIDs = @[currentApplicationBundleID, @"bar"].lt_set;
  aggregatedReceiptValidationStatusProvider =
      [[BZRFakeAggregatedReceiptValidationStatusProvider alloc] init];
  activator = OCMPartialMock([[BZRPeriodicReceiptValidatorActivator alloc]
      initWithReceiptValidator:receiptValidator
      validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
      bundledApplicationsIDs:bundledApplicationsIDs
      aggregatedValidationStatusProvider:aggregatedReceiptValidationStatusProvider]);

  lastValidationDate = [NSDate date];
});

context(@"deallocating object", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;

    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 1337 / 2 + 1, lastValidationDate);
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        BZRReceiptValidationStatusWithSubscriptionPeriod(1337);

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationStatusProvider:receiptValidationStatusProvider timeProvider:timeProvider
           bundledApplicationsIDs:bundledApplicationsIDs
           aggregatedValidationStatusProvider:aggregatedReceiptValidationStatusProvider];
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
    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        [BZRReceiptValidationStatus modelWithDictionary:@{
          @instanceKeypath(BZRReceiptValidationStatus, isValid): @YES,
          @instanceKeypath(BZRReceiptValidationStatus, validationDateTime): [NSDate date],
          @instanceKeypath(BZRReceiptValidationStatus, receipt): receipt
        } error:nil];

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should deactivate periodic validator if receipt validation status is nil", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = nil;

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

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = validationStatus;

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should deactivate the periodic validator if subscription was marked as expired before last "
     "validation", ^{
    OCMReject([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    NSDate *postExpirationDateTime =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
         dateByAddingTimeInterval:1];

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingProperty:@keypath(receiptValidationStatus, validationDateTime)
         withValue:postExpirationDateTime];

    OCMVerify([receiptValidator deactivate]);
  });

  it(@"should activate the periodic validator if subscription exists and is not marked as expired",
     ^{
    OCMReject([receiptValidator deactivate]);
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, activator.periodicValidationInterval,
                                            lastValidationDate);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([receiptValidator activateWithTrigger:OCMOCK_ANY]);
  });

  it(@"should activate the periodic validator if subscription was marked as expired before "
     "expiration", ^{
    OCMReject([receiptValidator deactivate]);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, activator.periodicValidationInterval,
                                            lastValidationDate);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    OCMVerify([receiptValidator activateWithTrigger:OCMOCK_ANY]);
  });

  it(@"should compute time to next validation to be less than zero", ^{
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, subscriptionPeriod / 2 + 2,
                                            lastValidationDate);

    OCMExpect([activator timerSignal:
        [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
      NSLog(@"%@", timeToNextValidation);
          return [timeToNextValidation doubleValue] < 0;
        }]]);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
    OCMVerifyAll((id)activator);
  });

  it(@"should send value immediately if time to next validation has passed", ^{
    __block RACSignal *validateReceiptSignal;
    OCMStub([receiptValidator activateWithTrigger:OCMOCK_ANY])
        .andDo(^(NSInvocation *invocation) {
          __unsafe_unretained RACSignal *signal;
          [invocation getArgument:&signal atIndex:2];
          validateReceiptSignal = signal;
        });
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, subscriptionPeriod / 2 + 1,
                                            lastValidationDate);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

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

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;

    expect(validateReceiptSignal).to.sendValuesWithCount(1);
  });

  it(@"should correctly compute time left to next validation", ^{
    BZRStubLoadedCacheEntryWithLastReceiptValidationDate(receiptValidationStatusProvider,
                                                         currentApplicationBundleID,
                                                         lastValidationDate);
    BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 133, lastValidationDate);

    OCMExpect([activator timerSignal:
               [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
      return abs([timeToNextValidation doubleValue] - (subscriptionPeriod / 2) + 133) < 0.0001;
    }]]);

    aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
    OCMVerifyAll((id)activator);
  });

  context(@"last validation dates of multiple applications", ^{
    it(@"should compute time left to next validation in relation to the earliest amongst the last "
       "validation dates", ^{
      NSDate *earlierDate = [NSDate dateWithTimeIntervalSince1970:30];
      NSDate *laterDate = [NSDate dateWithTimeIntervalSince1970:60];
      BZRStubLoadedCacheEntries(receiptValidationStatusProvider, @{
        @"foo": BZRCacheEntryWithActiveSubscriptionAndDate(earlierDate),
        @"bar": BZRCacheEntryWithActiveSubscriptionAndDate(laterDate)
      });
      BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 133, laterDate);

      OCMExpect([activator timerSignal:
                 [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
        return abs([timeToNextValidation doubleValue] - (subscriptionPeriod / 2) + 133 +
            [laterDate timeIntervalSinceDate:earlierDate]) < 0.0001;
      }]]);

      aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
      OCMVerifyAll((id)activator);
    });

    it(@"should compute time left to next validation in relation to last validation date of the "
       "receipt validation status whose subscription is not cancelled", ^{
      NSDate *earlierDate = [NSDate dateWithTimeIntervalSince1970:30];
      NSDate *laterDate = [NSDate dateWithTimeIntervalSince1970:60];

      auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                         initWithReceiptValidationStatus:
                         BZRReceiptValidationStatusWithExpiry(YES, YES)
                         cachingDateTime:earlierDate];
      BZRStubLoadedCacheEntries(receiptValidationStatusProvider, @{
        @"foo": cacheEntry,
        @"bar": BZRCacheEntryWithActiveSubscriptionAndDate(laterDate)
      });
      BZRStubCurrentTimeWithIntervalSinceDate(timeProvider, 133, laterDate);

      OCMExpect([activator timerSignal:
                 [OCMArg checkWithBlock:^BOOL(NSNumber *timeToNextValidation) {
        return abs([timeToNextValidation doubleValue] - (subscriptionPeriod / 2) + 133) < 0.0001;
      }]]);

      aggregatedReceiptValidationStatusProvider.receiptValidationStatus = receiptValidationStatus;
      OCMVerifyAll((id)activator);
    });
  });
});

SpecEnd
