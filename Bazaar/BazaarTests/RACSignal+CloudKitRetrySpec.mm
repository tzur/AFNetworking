// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+CloudKitRetry.h"

#import <CloudKit/CloudKit.h>

SpecBegin(RACSignal_CloudKitRetry)

it(@"should forward error without re-subscribing if error does not suggest retry", ^{
  auto error = [NSError lt_errorWithCode:1337];
  __block NSUInteger subscriptionCount = 0;
  auto signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
    RACSignal *currentSignal = subscriptionCount == 0 ? [RACSignal error:error] :
        [RACSignal return:@"foo"];
    subscriptionCount++;
    return [currentSignal subscribe:subscriber];
  }];

  auto recorder = [[signal bzr_retryCloudKitErrorIfNeeded:3] testRecorder];

  expect(recorder).will.sendError(error);
  expect(subscriptionCount).to.equal(1);
});

it(@"should re-subscribe if error suggests retry", ^{
  auto error = [NSError lt_errorWithCode:1337 userInfo:@{CKErrorRetryAfterKey: @0}];
  __block NSUInteger subscriptionCount = 0;
  auto signal =
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
        RACSignal *currentSignal = subscriptionCount == 0 ? [RACSignal error:error] :
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
  auto error = [NSError lt_errorWithCode:1337 userInfo:@{CKErrorRetryAfterKey: @0}];
  __block NSUInteger subscriptionCount = 0;
  auto signal =
      [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber> subscriber) {
        RACSignal *currentSignal = subscriptionCount <= 3 ? [RACSignal error:error] :
            [RACSignal return:@"foo"];
        subscriptionCount++;
        return [currentSignal subscribe:subscriber];
      }];

  auto recorder = [[signal bzr_retryCloudKitErrorIfNeeded:3] testRecorder];

  expect(recorder).will.sendError(error);
  expect(subscriptionCount).to.equal(4);
});

SpecEnd
