// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRMulticastContentFetcher.h"

#import "BZRTestUtils.h"

SpecBegin(BZRMulticastContentFetcher)

__block id<BZRProductContentFetcher> underlyingContentFetcher;
__block BZRMulticastContentFetcher *contentFetcher;

beforeEach(^{
  underlyingContentFetcher = OCMProtocolMock(@protocol(BZRProductContentFetcher));
  contentFetcher = [[BZRMulticastContentFetcher alloc]
                    initWithUnderlyingContentFetcher:underlyingContentFetcher];
});

it(@"should use the underlying fetcher to get the bundle of the product content", ^{
  BZRProduct *product = BZRProductWithIdentifierAndContent(@"foo");
  OCMStub([underlyingContentFetcher contentBundleForProduct:OCMOCK_ANY])
      .andReturn([RACSignal never]);

  [contentFetcher contentBundleForProduct:product];

  OCMVerify([underlyingContentFetcher contentBundleForProduct:product]);
});

context(@"content fetching", ^{
  __block BZRProduct *product;
  __block RACSubject *subject;

  beforeEach(^{
    product = BZRProductWithIdentifierAndContent(@"foo");
    subject = [RACSubject subject];
  });

  it(@"should not subscribe to the underlying fetcher signal if the fetching is already in "
     "progress", ^{
    OCMStub([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);
    [subject startCountingSubscriptions];

    [[contentFetcher fetchProductContent:product] testRecorder];
    [[contentFetcher fetchProductContent:product] testRecorder];
    [[contentFetcher fetchProductContent:product] testRecorder];

    expect([subject subscriptionCount]).to.equal(@1);
  });

  it(@"should not call the underlying content fetcher if the fetching is already in progress", ^{
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);
    OCMReject([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]);

    [[contentFetcher fetchProductContent:product] testRecorder];
    [[contentFetcher fetchProductContent:product] testRecorder];

    OCMVerifyAll(underlyingContentFetcher);
  });

  it(@"should return the current progress if the fetching is already in progress", ^{
    OCMStub([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);

    auto recorder = [[contentFetcher fetchProductContent:product] testRecorder];
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.5]];
    auto secondRecorder = [[contentFetcher fetchProductContent:product] testRecorder];
    [subject sendNext:[[LTProgress alloc] initWithProgress:0.9]];

    expect(recorder).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.5],
      [[LTProgress alloc] initWithProgress:0.9]
    ]);
    expect(secondRecorder).will.sendValues(@[
      [[LTProgress alloc] initWithProgress:0.9]
    ]);
  });

  it(@"should send error if the underlying fetcher errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);

    LLSignalTestRecorder *recorder = [[contentFetcher fetchProductContent:product] testRecorder];
    [subject sendError:error];

    expect(recorder).will.sendError(error);
  });

  it(@"should refetch content if there was an error fetching it the first time", ^{
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);

    [[contentFetcher fetchProductContent:product] testRecorder];
    [subject sendError:[NSError lt_errorWithCode:1337]];
    [[contentFetcher fetchProductContent:product] testRecorder];

    OCMVerifyAll(underlyingContentFetcher);
  });

  it(@"should refetch content if the fetching has completed before the second call", ^{
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);

    [[contentFetcher fetchProductContent:product] testRecorder];
    [subject sendCompleted];
    [[contentFetcher fetchProductContent:product] testRecorder];

    OCMVerifyAll(underlyingContentFetcher);
  });

  it(@"should refetch content if the number of subscribers was zero before the second call", ^{
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);
    OCMExpect([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(subject);

    [[[contentFetcher fetchProductContent:product] subscribeNext:^(id) {}] dispose];
    [[contentFetcher fetchProductContent:product] testRecorder];

    OCMVerifyAll(underlyingContentFetcher);
  });

  it(@"should dispose the underlying signal's disposable if signal was disposed", ^{
    __block BOOL disposeCalled = NO;

    OCMStub([underlyingContentFetcher fetchProductContent:OCMOCK_ANY]).andReturn(
        [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> __unused subscriber) {
          return [RACDisposable disposableWithBlock:^{
            disposeCalled = YES;
          }];
        }]);

    [[[contentFetcher fetchProductContent:product] subscribeNext:^(id) {}] dispose];

    expect(disposeCalled).to.beTruthy();
  });
});

SpecEnd
