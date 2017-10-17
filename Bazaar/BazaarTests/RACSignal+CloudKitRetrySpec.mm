// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+CloudKitRetry.h"

#import <CloudKit/CloudKit.h>

SpecBegin(RACSignal_CloudKitRetry)

__block NSError *retryableError;
__block NSError *nonRetryableError;

beforeEach(^{
  retryableError = [NSError errorWithDomain:CKErrorDomain code:CKErrorZoneBusy
                                   userInfo:@{CKErrorRetryAfterKey: @0}];
  nonRetryableError = [NSError lt_errorWithCode:1337];
});

it(@"should forward error without re-subscribing if error is not retryable", ^{
  __block NSUInteger subscriptionCount = 0;
  auto signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    RACSignal *currentSignal = subscriptionCount == 0 ? [RACSignal error:nonRetryableError] :
        [RACSignal return:@"foo"];
    subscriptionCount++;
    return [currentSignal subscribe:subscriber];
  }];

  auto recorder = [[signal bzr_retryCloudKitErrorIfNeeded:3] testRecorder];

  expect(recorder).will.sendError(nonRetryableError);
  expect(subscriptionCount).to.equal(1);
});

it(@"should re-subscribe if error is retryable", ^{
  __block NSUInteger subscriptionCount = 0;
  auto signal =
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
        RACSignal *currentSignal = subscriptionCount == 0 ? [RACSignal error:retryableError] :
            [RACSignal return:@"foo"];
        subscriptionCount++;
        return [currentSignal subscribe:subscriber];
      }];

  auto recorder = [[signal bzr_retryCloudKitErrorIfNeeded:3] testRecorder];

  expect(recorder).will.complete();
  expect(recorder).to.sendValues(@[@"foo"]);
  expect(subscriptionCount).to.equal(2);
});

it(@"should stop re-subscribing if error repeats more than requested retry attempts", ^{
  __block NSUInteger subscriptionCount = 0;
  auto signal =
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
        RACSignal *currentSignal = subscriptionCount <= 3 ? [RACSignal error:retryableError] :
            [RACSignal return:@"foo"];
        subscriptionCount++;
        return [currentSignal subscribe:subscriber];
      }];

  auto recorder = [[signal bzr_retryCloudKitErrorIfNeeded:3] testRecorder];

  expect(recorder).will.sendError(retryableError);
  expect(subscriptionCount).to.equal(4);
});

SpecEnd
