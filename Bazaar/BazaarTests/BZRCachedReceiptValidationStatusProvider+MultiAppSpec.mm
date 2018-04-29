// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"
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

  it(@"should complete successfully if self was deallocated when the signal is subscribed to", ^{
    __weak BZRCachedReceiptValidationStatusProvider * weakValidationStatusProvider;
    RACSignal *signal;

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

      signal = [provider fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set];
    }

    expect(signal).will.complete();
  });

  it(@"should not hold the provider strongly before subscribing to the signal", ^{
    __weak BZRCachedReceiptValidationStatusProvider * weakValidationStatusProvider;
    RACSignal *signal;

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

      signal = [provider fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set];
    }

    expect(weakValidationStatusProvider).to.beNil();
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

  it(@"should send cached receipt validation status for bundle IDs whose fetching has failed", ^{
    auto error = [NSError lt_errorWithCode:1337];
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal return:receiptValidationStatus]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal error:error]);
    auto secondReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    auto secondReceiptValidationStatusEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
        initWithReceiptValidationStatus:secondReceiptValidationStatus
        cachingDateTime:[NSDate date]];
    OCMStub([receiptValidationStatusCache
        loadCacheEntryOfApplicationWithBundleID:@"bar" error:[OCMArg anyObjectRef]])
        .andReturn(secondReceiptValidationStatusEntry);

    auto recorder = [[validationStatusProvider
                      fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[@{
      @"foo": receiptValidationStatus,
      @"bar": secondReceiptValidationStatus
    }]);
  });

  it(@"should ignore bundle IDs whose fetching has failed and have no cached recipt validation "
     "status entry", ^{
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

  it(@"should err if fetching all bundle IDs failed even if some were found in cache", ^{
    auto error = [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}];
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"foo"])
        .andReturn([RACSignal error:error]);
    OCMStub([validationStatusProvider fetchReceiptValidationStatus:@"bar"])
        .andReturn([RACSignal error:error]);
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
        initWithReceiptValidationStatus:receiptValidationStatus cachingDateTime:[NSDate date]];
    OCMStub([receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:@"foo"
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    auto recorder = [[validationStatusProvider
                      fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set] testRecorder];

    auto underlyingErrors = @[
      [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}],
      [NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}]
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
        eventError:[NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}]];
    auto secondValidationErrorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
        eventError:[NSError lt_errorWithCode:1337 userInfo:@{@"bar": @"ba"}]];
    expect([validationStatusProvider
            fetchReceiptValidationStatuses:@[@"foo", @"bar"].lt_set]).will.finish();
    expect(recorder).to.sendValues(@[firstValidationErrorEvent, secondValidationErrorEvent]);
  });
});

SpecEnd
