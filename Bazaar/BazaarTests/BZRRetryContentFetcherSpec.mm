// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRRetryContentFetcher.h"

#import <LTKit/LTProgress.h>

#import "BZRTestUtils.h"

SpecBegin(BZRRetryContentFetcher)

__block id<BZRProductContentFetcher> underlyingContentFetcher;
__block BZRRetryContentFetcher *contentFetcher;

beforeEach(^{
  underlyingContentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  contentFetcher = [[BZRRetryContentFetcher alloc]
                    initWithUnderlyingContentFetcher:underlyingContentFetcher numberOfRetries:2
                    initialDelay:0.0001];
});

it(@"should use the underlying fetcher to get the bundle of the product content", ^{
  BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
  OCMExpect([underlyingContentFetcher contentBundleForProduct:product])
      .andReturn([RACSignal empty]);

  [contentFetcher contentBundleForProduct:product];
  OCMVerifyAll((id)underlyingContentFetcher);
});

context(@"content fetching", ^{
  __block BZRProduct *product;
  __block RACSubject *subject;

  beforeEach(^{
    product = BZRProductWithIdentifierAndContent(@"foo");
    subject = [RACSubject subject];
  });

  it(@"should err if the signal erred on every try", ^{
    auto error = [NSError lt_errorWithCode:1337];
    RACSignal *signal = [RACSignal defer:^RACSignal *{
      LTProgress *progress = OCMClassMock([LTProgress class]);
      return [[RACSignal return:progress] concat:[RACSignal error:error]];
    }];
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(signal);

    auto recorder = [[contentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.sendValuesWithCount(3);
    expect(recorder).will.sendError(error);
  });

  it(@"should complete when the signal completes on second try", ^{
    auto error = [NSError lt_errorWithCode:1337];
    auto signalRetriesList = @[
      [[RACSignal return:[[LTProgress alloc] initWithProgress:0]] concat:[RACSignal error:error]],
      [RACSignal return:[[LTProgress alloc] initWithProgress:0.5]],
      [RACSignal return:[[LTProgress alloc] initWithProgress:1]]
    ];

    __block NSUInteger signalIndex = 0;
    RACSignal *signal = [RACSignal defer:^RACSignal *{
      return signalRetriesList[signalIndex++];
    }];
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(signal);

    auto recorder = [[contentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValuesWithCount(2);
    expect(recorder).will.matchValues(^BOOL(NSUInteger index, LTProgress *progress) {
      return index == 0 ? progress.progress == 0 : progress.progress == 0.5;
    });
  });
});

SpecEnd
