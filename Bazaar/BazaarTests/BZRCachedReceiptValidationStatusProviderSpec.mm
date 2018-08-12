// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeConversion.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

BZRReceiptValidationStatusCacheEntry *BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(
    BOOL isExpired, NSDate *cachingDateTime) {
  return [[BZRReceiptValidationStatusCacheEntry alloc]
          initWithReceiptValidationStatus:BZRReceiptValidationStatusWithExpiry(isExpired)
          cachingDateTime:cachingDateTime];
}

SpecBegin(BZRCachedReceiptValidationStatusProvider)

__block BZRKeychainStorage *keychainStorage;
__block BZRTimeProvider *timeProvider;
__block NSDate *currentTime;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingEventsSubject;
__block BZRReceiptValidationStatusCache *receiptValidationStatusCache;
__block NSString *applicationBundeID;
__block NSUInteger cachedEntryDaysToLive;
__block NSTimeInterval timeIntervalLongerThanCacheTTL;
__block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  timeProvider = OCMClassMock(BZRTimeProvider.class);
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingEventsSubject = [RACSubject subject];
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);
  receiptValidationStatusCache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  applicationBundeID = @"foo";
  cachedEntryDaysToLive = 1337;
  timeIntervalLongerThanCacheTTL =
      [BZRTimeConversion numberOfSecondsInDays:cachedEntryDaysToLive] + 1;
  validationStatusProvider =
      [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                         timeProvider:timeProvider
                                                   underlyingProvider:underlyingProvider
                                                cachedEntryDaysToLive:cachedEntryDaysToLive];
  currentTime = [NSDate date];
  OCMStub([timeProvider currentTime]).andReturn(currentTime);
});

context(@"deallocation", ^{
  __block BZRCachedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
  __block LLSignalTestRecorder *recorder;

  it(@"events signal should complete when object is deallocated", ^{
    @autoreleasepool {
      auto validationStatusProvider = [[BZRCachedReceiptValidationStatusProvider alloc]
                                       initWithCache:receiptValidationStatusCache
                                       timeProvider:timeProvider
                                       underlyingProvider:underlyingProvider
                                       cachedEntryDaysToLive:cachedEntryDaysToLive];
      weakValidationStatusProvider = validationStatusProvider;
      recorder = [[validationStatusProvider eventsSignal] testRecorder];
    }

    expect(weakValidationStatusProvider).to.beNil();
    expect(recorder).to.complete();
  });

  it(@"should dealloc the provider while fetching", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"]).andReturn([RACSignal never]);
    @autoreleasepool {
      auto validationStatusProvider = [[BZRCachedReceiptValidationStatusProvider alloc]
                                       initWithCache:receiptValidationStatusCache
                                       timeProvider:timeProvider
                                       underlyingProvider:underlyingProvider
                                       cachedEntryDaysToLive:cachedEntryDaysToLive];
      weakValidationStatusProvider = validationStatusProvider;
      recorder = [[validationStatusProvider fetchReceiptValidationStatus:@"foo"] testRecorder];
    }

    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"handling errors", ^{
  it(@"should send event sent by the underlying provider", ^{
    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];
    BZREvent *event = OCMClassMock([BZREvent class]);
    [underlyingEventsSubject sendNext:event];

    expect(recorder).will.sendValues(@[event]);
  });
});

context(@"fetching receipt validation status", ^{
  it(@"should send receipt validation status sent by the underlying provider", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    RACSignal *validateSignal =
        [[validationStatusProvider fetchReceiptValidationStatus:@"foo"] testRecorder];

    expect(validateSignal).will.complete();
    expect(validateSignal).will.sendValues(@[receiptValidationStatus]);
  });

  it(@"should save receipt validation status to cache", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMExpect([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                        applicationBundleID:applicationBundeID
                                                      error:[OCMArg anyObjectRef]]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus:@"foo"];

    expect(validateSignal).will.complete();
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should err when underlying receipt validitation status provider errs", ^{
    auto error = [NSError lt_errorWithCode:1337];
    id<BZRReceiptValidationStatusProvider> underlyingProvider =
        OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);
    OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider
                                                  cachedEntryDaysToLive:cachedEntryDaysToLive];
    LLSignalTestRecorder *recorder =
        [[validationStatusProvider fetchReceiptValidationStatus:@"foo"] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

context(@"KVO compliance", ^{
  __block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

  beforeEach(^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                      applicationBundleID:applicationBundeID
                                                    error:[OCMArg anyObjectRef]]).andReturn(YES);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider
                                                  cachedEntryDaysToLive:cachedEntryDaysToLive];
  });
});

context(@"invalidating cache", ^{
  it(@"should not store invalidated receipt validation status if receipt validation status was "
     "fetched successfully", ^{
    auto fetchedReceiptValidationStatus =
        [BZRReceiptValidationStatusWithSubscriptionIdentifier(@"bar")
         modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptValidationStatus,
         receipt.subscription.isExpired) withValue:@NO];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:fetchedReceiptValidationStatus]);

    auto cachingDateTime = [currentTime dateByAddingTimeInterval:-timeIntervalLongerThanCacheTTL];
    auto cacheEntry =
        BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(NO, cachingDateTime);
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    OCMReject([receiptValidationStatusCache storeCacheEntry:
        [OCMArg checkWithBlock:^BOOL(BZRReceiptValidationStatusCacheEntry *cacheEntry) {
          return cacheEntry.receiptValidationStatus.receipt.subscription.isExpired;
        }]
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).to.finish();
  });

  it(@"should not invalidate cache if the subscription is expired", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);
    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    auto cacheEntry =
        BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(YES, [NSDate date]);
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    expect([validationStatusProvider fetchReceiptValidationStatus:@"foo"]).to.finish();
  });

  it(@"should not invalidate cache the first error date is nil", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:applicationBundeID])
        .andReturn([RACSignal error:error]);

    auto cacheEntry = BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(NO, [NSDate date]);
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
             error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    auto cacheEntryWithExpiredSubscription =
        [cacheEntry modelByOverridingPropertyAtKeypath:
         @keypath(cacheEntry, receiptValidationStatus.receipt.subscription.isExpired)
         withValue:@YES];

    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to.finish();
    OCMReject([receiptValidationStatusCache storeCacheEntry:cacheEntryWithExpiredSubscription
        applicationBundleID:applicationBundeID error:[OCMArg anyObjectRef]]);
  });

  it(@"should not invalidate cache if the time to invalidation has not passed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:applicationBundeID])
        .andReturn([RACSignal error:error]);

    auto dateInRecentPast = [NSDate
        dateWithTimeInterval:-[BZRTimeConversion numberOfSecondsInDays:cachedEntryDaysToLive / 2]
                   sinceDate:timeProvider.currentTime];

    auto cacheEntry = BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(NO, [NSDate date]);
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
             error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);
    OCMStub([receiptValidationStatusCache
             firstErrorDateTimeForApplicationBundleID:applicationBundeID])
        .andReturn(dateInRecentPast);

    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                        applicationBundleID:OCMOCK_ANY
                                                      error:[OCMArg anyObjectRef]]);

    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to.finish();
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should invalidate cache if the time to invalidation has passed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:applicationBundeID])
        .andReturn([RACSignal error:error]);

    auto dateInFarPast = [NSDate
        dateWithTimeInterval:-[BZRTimeConversion numberOfSecondsInDays:cachedEntryDaysToLive * 2]
                   sinceDate:timeProvider.currentTime];

    auto cacheEntry = BZRCacheEntryWithReceiptValidationStatusAndCachingDateTime(NO, [NSDate date]);
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
             error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);
    OCMStub([receiptValidationStatusCache
             firstErrorDateTimeForApplicationBundleID:applicationBundeID])
        .andReturn(dateInFarPast);

    auto cacheEntryWithExpiredSubscription =
        [cacheEntry modelByOverridingPropertyAtKeypath:
         @keypath(cacheEntry, receiptValidationStatus.receipt.subscription.isExpired)
         withValue:@YES];

    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to.finish();
    OCMVerify([receiptValidationStatusCache storeCacheEntry:cacheEntryWithExpiredSubscription
        applicationBundleID:applicationBundeID error:[OCMArg anyObjectRef]]);
  });
});

context(@"storing first error date", ^{
  it(@"should save first error date on first failure", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);

    OCMExpect([receiptValidationStatusCache storeFirstErrorDateTime:currentTime
                                                applicationBundleID:applicationBundeID]);

    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to
        .finish();
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should not store the second error date on failure", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);

    OCMExpect([receiptValidationStatusCache
        firstErrorDateTimeForApplicationBundleID:applicationBundeID]).andReturn([NSDate date]);
    OCMReject([receiptValidationStatusCache storeFirstErrorDateTime:OCMOCK_ANY
                                                applicationBundleID:applicationBundeID]);

    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to.finish();

    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should remove the first error date on success", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMExpect([receiptValidationStatusCache storeFirstErrorDateTime:nil
                                                applicationBundleID:applicationBundeID]);
    expect([validationStatusProvider fetchReceiptValidationStatus:applicationBundeID]).to.finish();

    OCMVerifyAll((id)receiptValidationStatusCache);
  });
});

context(@"revalidating invalidated receipt cache", ^{
  it(@"should not revalidate cache if the subscription is not expired", ^{
    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    auto cacheEntry =
        [[BZRReceiptValidationStatusCacheEntry alloc]
         initWithReceiptValidationStatus:BZRReceiptValidationStatusWithExpiry(NO)
                         cachingDateTime:[NSDate date]];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    [validationStatusProvider revertPrematureInvalidationOfReceiptValidationStatus:@"foo"];
  });

  it(@"should not revalidate cache if cancellation date exists", ^{
    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, YES);
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[NSDate date]];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    [validationStatusProvider revertPrematureInvalidationOfReceiptValidationStatus:@"foo"];
  });

  it(@"should not revalidate cache if the validation date comes after the expiration date", ^{
    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    auto validationDate =
        [receiptValidationStatus.receipt.subscription.expirationDateTime
         dateByAddingTimeInterval:1];
    receiptValidationStatus =
        [receiptValidationStatus
         modelByOverridingPropertyAtKeypath:@keypath(receiptValidationStatus, validationDateTime)
         withValue:validationDate];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[NSDate date]];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    [validationStatusProvider revertPrematureInvalidationOfReceiptValidationStatus:@"foo"];
  });

  it(@"should not revalidate cache if the time to live has passed", ^{
    OCMReject([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
        applicationBundleID:OCMOCK_ANY error:[OCMArg anyObjectRef]]);

    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    auto timeIntervalSinceCaching =
        [BZRTimeConversion numberOfSecondsInDays:(cachedEntryDaysToLive + 10)];
    auto cachingDateTime = [[NSDate date] dateByAddingTimeInterval:-timeIntervalSinceCaching];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:cachingDateTime];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    [validationStatusProvider revertPrematureInvalidationOfReceiptValidationStatus:@"foo"];
  });

  it(@"should revalidate cache if it was invalidated", ^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES, NO);
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[timeProvider currentTime]];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:OCMOCK_ANY
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    auto cacheEntryWithNonExpiredSubscription =
        [cacheEntry modelByOverridingPropertyAtKeypath:
         @keypath(cacheEntry, receiptValidationStatus.receipt.subscription.isExpired)
         withValue:@NO];

    [validationStatusProvider revertPrematureInvalidationOfReceiptValidationStatus:@"foo"];
    OCMVerify([receiptValidationStatusCache storeCacheEntry:cacheEntryWithNonExpiredSubscription
        applicationBundleID:applicationBundeID error:[OCMArg anyObjectRef]]);
  });
});

SpecEnd
