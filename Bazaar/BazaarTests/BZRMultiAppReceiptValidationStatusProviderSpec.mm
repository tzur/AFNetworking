// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiAppReceiptValidationStatusProvider.h"

#import <LTKit/NSDictionary+Functional.h>

#import "BZRCachedReceiptValidationStatusProvider.h"
#import "BZREvent.h"
#import "BZRMultiAppReceiptValidationStatusAggregator.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRReceiptValidationStatusProvider.h"
#import "BZRTestUtils.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRMultiAppReceiptValidationStatusProvider)

__block BZRCachedReceiptValidationStatusProvider *underlyingProvider;
__block RACSubject *underlyingProviderEventsSubject;
__block BZRMultiAppReceiptValidationStatusAggregator *aggregator;
__block BZRReceiptValidationStatusCache *receiptValidationStatusCache;
__block NSSet<NSString *> *bundleIDsForValidation;
__block BZRMultiAppReceiptValidationStatusProvider *multiAppReceiptValidationStatusProvider;

beforeEach(^{
  underlyingProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
  underlyingProviderEventsSubject = [RACSubject subject];
  OCMStub([underlyingProvider eventsSignal]).andReturn(underlyingProviderEventsSubject);
  receiptValidationStatusCache = OCMClassMock([BZRReceiptValidationStatusCache class]);
  OCMStub([underlyingProvider cache]).andReturn(receiptValidationStatusCache);

  aggregator = OCMClassMock([BZRMultiAppReceiptValidationStatusAggregator class]);
  bundleIDsForValidation = @[@"com.lt.otherApp", @"com.lt.anotherApp"].lt_set;
  multiAppReceiptValidationStatusProvider = [[BZRMultiAppReceiptValidationStatusProvider alloc]
      initWithUnderlyingProvider:underlyingProvider aggregator:aggregator
      bundleIDsForValidation:bundleIDsForValidation];
});

context(@"fetching receipt validation status", ^{
  it(@"should err if aggregator returned nil", ^{
    auto bundleIDToReceiptValidationStatus =
        @{@"com.lt.otherApp": BZRReceiptValidationStatusWithExpiry(NO)};
    OCMStub([underlyingProvider fetchReceiptValidationStatuses:OCMOCK_ANY])
        .andReturn([RACSignal return:bundleIDToReceiptValidationStatus]);

    expect([multiAppReceiptValidationStatusProvider fetchReceiptValidationStatus]).to
        .matchError(^BOOL(NSError *error) {
          return error.code == BZRErrorCodeReceiptValidationFailed;
        });

    OCMVerify([aggregator
               aggregateMultiAppReceiptValidationStatuses:bundleIDToReceiptValidationStatus]);
  });

  it(@"should err if underlying provider erred", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingProvider fetchReceiptValidationStatuses:OCMOCK_ANY])
        .andReturn([RACSignal error:error]);

    expect([multiAppReceiptValidationStatusProvider fetchReceiptValidationStatus]).to
        .sendError(error);
  });

  it(@"should send the value returned by the aggregator on the receipt validation statuses", ^{
    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    OCMStub([underlyingProvider fetchReceiptValidationStatuses:bundleIDsForValidation])
        .andReturn([RACSignal return:@{@"foo": receiptValidationStatus}]);
    OCMStub([aggregator aggregateMultiAppReceiptValidationStatuses:OCMOCK_ANY])
        .andReturn(receiptValidationStatus);

    auto recorder =
        [[multiAppReceiptValidationStatusProvider fetchReceiptValidationStatus] testRecorder];

    expect(recorder).to.complete();
    expect(recorder).to.sendValues(@[receiptValidationStatus]);
  });
});

it(@"should set the multi-app receipt validation status dictionary to be the one returned by the "
   "underlying provider", ^{
  auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
  auto multiAppReceiptValidationStatues = @{@"foo": receiptValidationStatus};
  OCMStub([underlyingProvider fetchReceiptValidationStatuses:bundleIDsForValidation])
      .andReturn([RACSignal return:multiAppReceiptValidationStatues]);
  OCMStub([aggregator aggregateMultiAppReceiptValidationStatuses:OCMOCK_ANY])
      .andReturn(receiptValidationStatus);

  expect([multiAppReceiptValidationStatusProvider fetchReceiptValidationStatus]).to.complete();
  expect(multiAppReceiptValidationStatusProvider.multiAppReceiptValidationStatus).to
      .equal(multiAppReceiptValidationStatues);
});

context(@"aggregated receipt validation status property", ^{
  context(@"loading aggregated receipt validation status from cache", ^{
    it(@"should be nil if couldn't load any receipt validation status", ^{
      expect(multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus).to.beNil();
    });

    it(@"should be nil if aggregator returned nil on the receipt validation statuses from cache", ^{
      underlyingProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
      OCMStub([underlyingProvider cache]).andReturn(receiptValidationStatusCache);
      OCMStub([receiptValidationStatusCache loadReceiptValidationStatusCacheEntries:OCMOCK_ANY])
          .andReturn(@{});

      multiAppReceiptValidationStatusProvider = [[BZRMultiAppReceiptValidationStatusProvider alloc]
          initWithUnderlyingProvider:underlyingProvider aggregator:aggregator
          bundleIDsForValidation:bundleIDsForValidation];

      expect(multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus).to.beNil();
      OCMVerify([aggregator aggregateMultiAppReceiptValidationStatuses:@{}]);
    });

    it(@"should set the property to be the value returned by the aggregator", ^{
      underlyingProvider = OCMClassMock([BZRCachedReceiptValidationStatusProvider class]);
      auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
      auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                         initWithReceiptValidationStatus:receiptValidationStatus
                         cachingDateTime:[NSDate date]];
      OCMStub([receiptValidationStatusCache
          loadReceiptValidationStatusCacheEntries:OCMOCK_ANY])
          .andReturn(@{@"foo": cacheEntry});
      OCMStub([aggregator aggregateMultiAppReceiptValidationStatuses:OCMOCK_ANY])
          .andReturn(receiptValidationStatus);

      multiAppReceiptValidationStatusProvider = [[BZRMultiAppReceiptValidationStatusProvider alloc]
          initWithUnderlyingProvider:underlyingProvider aggregator:aggregator
          bundleIDsForValidation:bundleIDsForValidation];

      expect(multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus).to
          .equal(receiptValidationStatus);
    });
  });

  it(@"should not update if aggregator return nil when fetching receipt validation statuses", ^{
    OCMStub([underlyingProvider fetchReceiptValidationStatuses:OCMOCK_ANY])
        .andReturn([RACSignal return:@{}]);

    expect(multiAppReceiptValidationStatusProvider.aggregatedReceiptValidationStatus).to.beNil();
  });

  it(@"should update if aggregated receipt validation status was fetched successfully", ^{
    auto recorder =
        [RACObserve(multiAppReceiptValidationStatusProvider, aggregatedReceiptValidationStatus)
         testRecorder];

    auto receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    OCMStub([underlyingProvider fetchReceiptValidationStatuses:bundleIDsForValidation])
        .andReturn([RACSignal return:@{@"com.lt.otherApp": receiptValidationStatus}]);
    OCMStub([aggregator
        aggregateMultiAppReceiptValidationStatuses:@{@"com.lt.otherApp": receiptValidationStatus}])
        .andReturn(receiptValidationStatus);

    expect([multiAppReceiptValidationStatusProvider fetchReceiptValidationStatus]).to.complete();
    expect(recorder).to.sendValues(@[[NSNull null], receiptValidationStatus]);
  });
});

context(@"sending events", ^{
  it(@"should send events sent by the underlyingProvider", ^{
    auto recorder = [multiAppReceiptValidationStatusProvider.eventsSignal testRecorder];

    auto event = [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
                                     eventError:[NSError lt_errorWithCode:1337]];
    [underlyingProviderEventsSubject sendNext:event];

    expect(recorder).to.sendValues(@[event]);
  });
});

SpecEnd
