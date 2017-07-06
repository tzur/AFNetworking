// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRCachedReceiptValidationStatusProvider)

__block BZRKeychainStorage *keychainStorage;
__block id<BZRTimeProvider> timeProvider;
__block NSDate *currentTime;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingEventsSubject;
__block BZRReceiptValidationStatusCache *receiptValidationStatusCache;
__block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingEventsSubject = [RACSubject subject];
  receiptValidationStatusCache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);
  currentTime = OCMClassMock([NSDate class]);
  OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
});

context(@"initialization", ^{
  it(@"should load validation status and last cached date from cache", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:validationStatus
                       cachingDateTime:currentTime];
    OCMExpect([receiptValidationStatusCache loadCacheEntry:[OCMArg anyObjectRef]])
        .andReturn(cacheEntry);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should set the validation status and validation date to nil if failed to read from cache", ^{
    OCMStub([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:[NSError lt_errorWithCode:1337]]]);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];

    expect(validationStatusProvider.receiptValidationStatus).to.beNil();
    expect(validationStatusProvider.lastReceiptValidationDate).to.beNil();
  });
});

context(@"deallocation", ^{
  __block BZRCachedReceiptValidationStatusProvider __weak *weakValidationStatusProvider;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    OCMStub([underlyingProvider eventsSignal]).andReturn([RACSignal empty]);
  });

  it(@"events signal should complete when object is deallocated", ^{
    @autoreleasepool {
      auto validationStatusProvider = [[BZRCachedReceiptValidationStatusProvider alloc]
                                       initWithCache:receiptValidationStatusCache
                                       timeProvider:timeProvider
                                       underlyingProvider:underlyingProvider];
      weakValidationStatusProvider = validationStatusProvider;
      recorder = [[validationStatusProvider eventsSignal] testRecorder];
    }

    expect(weakValidationStatusProvider).to.beNil();
    expect(recorder).to.complete();
  });

  it(@"should dealloc the provider while fetching", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus]).andReturn([RACSignal never]);
    @autoreleasepool {
      auto validationStatusProvider = [[BZRCachedReceiptValidationStatusProvider alloc]
                                       initWithCache:receiptValidationStatusCache
                                       timeProvider:timeProvider
                                       underlyingProvider:underlyingProvider];
      weakValidationStatusProvider = validationStatusProvider;
      recorder = [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];
    }

    expect(weakValidationStatusProvider).to.beNil();
  });
});

context(@"handling errors", ^{
  it(@"should send event sent by the underlying provider", ^{
    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];
    BZREvent *event = OCMClassMock([BZREvent class]);
    [underlyingEventsSubject sendNext:event];

    expect(recorder).will.sendValues(@[event]);
  });

  it(@"should send error event when failed to store receipt validation status", ^{
    NSError *underlyingError = OCMClassMock([NSError class]);
    OCMStub([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                                    error:[OCMArg setTo:underlyingError]]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
    LLSignalTestRecorder *recorder = [validationStatusProvider.eventsSignal testRecorder];

    expect([validationStatusProvider fetchReceiptValidationStatus]).will.complete();
    expect(recorder).will.matchValue(0, ^BOOL(BZREvent *event) {
      return event.eventError == underlyingError &&
          [event.eventType isEqual:$(BZREventTypeNonCriticalError)];
    });
  });

  it(@"should send error event when failed to read from cache", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([receiptValidationStatusCache loadCacheEntry:[OCMArg setTo:error]]);
    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];

    expect(validationStatusProvider.eventsSignal).will.matchValue(0, ^BOOL(BZREvent *event) {
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] && event.eventError == error;
    });
  });
});

context(@"fetching receipt validation status", ^{
  beforeEach(^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
  });

  it(@"should send receipt validation status sent by the underlying provider", ^{
    RACSignal *validateSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validateSignal).will.complete();
    expect(validateSignal).will.sendValues(@[receiptValidationStatus]);
  });

  it(@"should save receipt validation status to cache", ^{
    OCMExpect([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                                      error:[OCMArg anyObjectRef]]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should update receipt validation status and validation date after fetching", ^{
    OCMExpect([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY
                                                      error:[OCMArg anyObjectRef]]);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);
    OCMVerifyAll((id)receiptValidationStatusCache);
  });

  it(@"should update receipt validation status and validation date if storing to cache has "
     " failed", ^{
    OCMStub([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY error:[OCMArg anyObjectRef]])
          .andReturn(NO);

    RACSignal *validateSignal = [validationStatusProvider fetchReceiptValidationStatus];

    expect(validateSignal).will.complete();
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);
  });

  it(@"should not modify receipt validation status if failed to write to cache", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    NSDate *validationDate = [NSDate date];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:validationStatus
                       cachingDateTime:validationDate];
    OCMStub([receiptValidationStatusCache loadCacheEntry:[OCMArg anyObjectRef]])
        .andReturn(cacheEntry);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];

    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);

    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY error:[OCMArg setTo:error]]);
    [validationStatusProvider fetchReceiptValidationStatus];
    expect(validationStatusProvider.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(validationDate);
  });

  it(@"should err when underlying receipt validitation status provider errs", ^{
    NSError *error = OCMClassMock([NSError class]);
    id<BZRReceiptValidationStatusProvider> underlyingProvider =
        OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
    OCMStub([underlyingProvider fetchReceiptValidationStatus]).andReturn([RACSignal error:error]);
    OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
    LLSignalTestRecorder *recorder =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).will.sendError(error);
  });
});

context(@"KVO compliance", ^{
  __block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

  beforeEach(^{
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([receiptValidationStatusCache storeCacheEntry:OCMOCK_ANY error:[OCMArg anyObjectRef]])
        .andReturn(YES);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
  });

  it(@"should notify the observer when receipt validation status changes", ^{
    LLSignalTestRecorder *recorder =
        [RACObserve(validationStatusProvider, receiptValidationStatus) testRecorder];

    expect([validationStatusProvider fetchReceiptValidationStatus]).to.complete();
    expect(recorder).will.sendValues(@[[NSNull null], receiptValidationStatus]);
  });

  it(@"should notify the observer when last receipt validation date changes", ^{
    LLSignalTestRecorder *recorder =
        [RACObserve(validationStatusProvider, lastReceiptValidationDate) testRecorder];

    expect([validationStatusProvider fetchReceiptValidationStatus]).to.complete();
    expect(recorder).will.sendValues(@[[NSNull null], currentTime]);
  });
});

context(@"expiring subscription", ^{
  it(@"should change subscription status to expired", ^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    OCMStub([underlyingProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                error:[OCMArg anyObjectRef]]).andReturn(YES);

    validationStatusProvider =
        [[BZRCachedReceiptValidationStatusProvider alloc] initWithCache:receiptValidationStatusCache
                                                           timeProvider:timeProvider
                                                     underlyingProvider:underlyingProvider];
    LLSignalTestRecorder *validationSignal =
        [[validationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(validationSignal).will.complete();
    expect(validationStatusProvider.receiptValidationStatus).to.equal(receiptValidationStatus);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);

    [validationStatusProvider expireSubscription];
    expect(validationStatusProvider.receiptValidationStatus.receipt.subscription.isExpired).to
        .equal(YES);
    expect(validationStatusProvider.lastReceiptValidationDate).to.equal(currentTime);
  });
});

SpecEnd
