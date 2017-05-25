// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRCachedContentFetcher.h"

#import "BZRTestUtils.h"

SpecBegin(BZRCachedContentFetcher)

__block id<BZRProductContentFetcher> underlyingContentFetcher;
__block BZRCachedContentFetcher *contentFetcher;

beforeEach(^{
  underlyingContentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  contentFetcher =
      [[BZRCachedContentFetcher alloc] initWithUnderlyingContentFetcher:underlyingContentFetcher];
});

it(@"should use the underlying fetcher to get the bundle of the product content", ^{
  BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");

  [contentFetcher contentBundleForProduct:product];

  OCMVerify([underlyingContentFetcher contentBundleForProduct:product]);
});

context(@"fetching content", ^{
  __block BZRProduct *product;
  __block NSBundle *bundle;
  __block LTProgress *progress;

  beforeEach(^{
    product = BZRProductWithIdentifierAndContent(@"foo");
    bundle = OCMClassMock([NSBundle class]);
    progress = [[LTProgress alloc] initWithResult:bundle];
  });

  it(@"should send the content bundle without calling fetch if the content already exists", ^{
    OCMStub([underlyingContentFetcher contentBundleForProduct:product])
        .andReturn([RACSignal return:bundle]);
    OCMReject([underlyingContentFetcher fetchProductContent:product]);

    LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[progress]);
  });

  it(@"should send content bundle provided by content fetcher", ^{
    OCMStub([underlyingContentFetcher contentBundleForProduct:product])
        .andReturn([RACSignal return:nil]);
    OCMStub([underlyingContentFetcher fetchProductContent:product])
        .andReturn([RACSignal return:progress]);

    LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];

    expect(recorder).will.complete();
    expect(recorder).will.sendValues(@[progress]);
  });

  it(@"should err when content fetcher errs", ^{
    OCMStub([underlyingContentFetcher contentBundleForProduct:product])
        .andReturn([RACSignal return:nil]);
    NSError *fetchContentError = OCMClassMock([NSError class]);
    OCMStub([underlyingContentFetcher fetchProductContent:OCMOCK_ANY])
        .andReturn([RACSignal error:fetchContentError]);

    RACSignal *fetchingContent = [contentFetcher fetchProductContent:product];

    expect(fetchingContent).will.sendError(fetchContentError);
  });
});

SpecEnd
