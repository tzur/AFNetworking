// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRCachedReceiptValidationStatusProvider_MultiApp)

__block id<BZRTimeProvider> timeProvider;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block id<BZRReceiptValidationStatusProvider> underlyingProvider;
__block RACSubject *underlyingEventsSubject;
__block BZRReceiptValidationStatusCache *receiptValidationStatusCache;
__block BZRCachedReceiptValidationStatusProvider *validationStatusProvider;

beforeEach(^{
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  underlyingEventsSubject = [RACSubject subject];
  receiptValidationStatusCache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingEventsSubject);
  OCMStub([timeProvider currentTime]).andReturn([RACSignal return:[NSDate date]]);

  validationStatusProvider = OCMPartialMock([[BZRCachedReceiptValidationStatusProvider alloc]
                                             initWithCache:receiptValidationStatusCache
                                             timeProvider:timeProvider
                                             underlyingProvider:underlyingProvider
                                             cachedEntryDaysToLive:14]);
});

afterEach(^{
  validationStatusProvider = nil;
});

context(@"deallocating object", ^{
  it(@"should finish successfully when all strong references are relinquished", ^{
    RACSignal *signal;

    @autoreleasepool {
      BZRCachedReceiptValidationStatusProvider *provider =
          OCMPartialMock([[BZRCachedReceiptValidationStatusProvider alloc]
                          initWithCache:receiptValidationStatusCache
                          timeProvider:timeProvider
                          underlyingProvider:underlyingProvider]);

      auto firstReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
      auto secondReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);

      OCMStub([provider fetchReceiptValidationStatus:@"foo"])
          .andReturn([RACSignal return:firstReceiptValidationStatus]);
      OCMStub([provider fetchReceiptValidationStatus:@"bar"])
          .andReturn([RACSignal return:secondReceiptValidationStatus]);

      signal = [provider fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set];
    }

    expect(signal).will.complete();
  });

  it(@"should dealloc when all strong references are relinquished", ^{
    BZRCachedReceiptValidationStatusProvider * __weak weakValidationStatusProvider;
    LLSignalTestRecorder *recorder;

    @autoreleasepool {
      BZRCachedReceiptValidationStatusProvider *provider =
          [[BZRCachedReceiptValidationStatusProvider alloc]
           initWithCache:receiptValidationStatusCache
           timeProvider:timeProvider
           underlyingProvider:underlyingProvider
           cachedEntryDaysToLive:14];
      weakValidationStatusProvider = provider;

      OCMStub([underlyingProvider fetchReceiptValidationStatus:@"foo"])
          .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(YES)]);
      OCMStub([underlyingProvider fetchReceiptValidationStatus:@"bar"])
          .andReturn([RACSignal return:BZRReceiptValidationStatusWithExpiry(NO)]);

      recorder = [[provider fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];
    }

    expect(weakValidationStatusProvider).to.beNil();
    expect(recorder).will.complete();
  });
});

context(@"fetching receipt validation status of multiple apps", ^{
  it(@"should fetch receipt validation status of the requested bundle IDs", ^{
    auto firstReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    auto secondReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);

    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:firstReceiptValidationStatus]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal return:secondReceiptValidationStatus]);

    auto recorder = [[validationStatusProvider
                      fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@{
          @"foo": firstReceiptValidationStatus,
          @"bar": secondReceiptValidationStatus
        }]);
  });

  it(@"should ignore bundle IDs whose fetching has failed", ^{
    auto error = [NSError lt_errorWithCode:1337];

    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal error:error]);

    auto recorder = [[validationStatusProvider
                      fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@{@"foo": receiptValidationStatus}]);
  });

  it(@"should err if fetching all bundle IDs failed", ^{
    auto error = [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}];
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal error:error]);

    auto recorder = [[validationStatusProvider
                      fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];

    auto underlyingErrors = @[
      [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba", kBZRApplicationBundleIDKey: @"foo"}],
      [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba", kBZRApplicationBundleIDKey: @"bar"}]
    ];
    expect(recorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeReceiptValidationFailed &&
          [error.lt_underlyingErrors isEqualToArray:underlyingErrors];
    });
  });

  it(@"should send event for every bundle ID whose fetching has failed", ^{
    auto error = [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}];
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal error:error]);

    auto recorder = [validationStatusProvider.eventsSignal testRecorder];

    auto firstValidationErrorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
        eventError:[NSError lt_errorWithCode:1337 userInfo:@{
          @"bar": @"ba",
          kBZRApplicationBundleIDKey: @"foo"
        }]];
    auto secondValidationErrorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
        eventError:[NSError lt_errorWithCode:1337 userInfo:@{
          @"bar": @"ba",
          kBZRApplicationBundleIDKey: @"bar"
        }]];
    expect([validationStatusProvider
            fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set]).will.finish();
    expect(recorder).to.sendValues(@[firstValidationErrorEvent, secondValidationErrorEvent]);
  });
});

context(@"loading receipt validation status cache entry from cache", ^{
  __block BZRReceiptValidationStatusCacheEntry *cacheEntry;

  beforeEach(^{
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                  initWithReceiptValidationStatus:receiptValidationStatus
                  cachingDateTime:[NSDate date]];
  });

  it(@"should return dictionary with the receipt validation status of the requested bundle IDs", ^{
    auto secondReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    auto secondReceiptValidationStatusCacheEntry =
        [[BZRReceiptValidationStatusCacheEntry alloc]
         initWithReceiptValidationStatus:secondReceiptValidationStatus
         cachingDateTime:[NSDate dateWithTimeIntervalSince1970:1337]];

    OCMStub([validationStatusProvider loadReceiptValidationStatusCacheEntryFromStorage:@"foo"])
        .andReturn(cacheEntry);
    OCMStub([validationStatusProvider loadReceiptValidationStatusCacheEntryFromStorage:@"bar"])
        .andReturn(secondReceiptValidationStatusCacheEntry);

    auto cacheEntries =
        [validationStatusProvider loadReceiptValidationStatusCacheEntries:@[@"foo", @"bar"].lt_set];

    expect(cacheEntries).to.equal(@{
      @"foo": cacheEntry,
      @"bar": secondReceiptValidationStatusCacheEntry
    });
  });

  it(@"should return dictionary without bundleIDs whose cache entry wasn't found", ^{
    OCMStub([validationStatusProvider loadReceiptValidationStatusCacheEntryFromStorage:@"foo"])
        .andReturn(cacheEntry);

    auto cacheEntries =
        [validationStatusProvider loadReceiptValidationStatusCacheEntries:@[@"foo", @"bar"].lt_set];

    expect(cacheEntries).to.equal(@{@"foo": cacheEntry});
  });
});

SpecEnd
