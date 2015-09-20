// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTForegroundOperation.h"

#import "LTOperationsExecutor.h"

SpecBegin(LTForegroundOperation)

beforeEach(^{
  [LTForegroundOperation executor].executionAllowed = NO;
});

it(@"should execute block when explicitly starting operation", ^{
  __block BOOL didExecute = NO;

  LTForegroundOperation *operation = [LTForegroundOperation blockOperationWithBlock:^{
    didExecute = YES;
  }];
  [operation start];

  expect(didExecute).to.beTruthy();
});

it(@"should not execute when execution is not allowed", ^{
  __block BOOL didExecute = NO;

  LTForegroundOperation *operation = [LTForegroundOperation blockOperationWithBlock:^{
    didExecute = YES;
  }];
  operation.foregroundBlock();

  expect(didExecute).to.beFalsy();
});

it(@"should not execute when execution is allowed", ^{
  __block BOOL didExecute = NO;

  LTForegroundOperation *operation = [LTForegroundOperation blockOperationWithBlock:^{
    didExecute = YES;
  }];

  [LTForegroundOperation executor].executionAllowed = YES;
  operation.foregroundBlock();

  expect(didExecute).to.beTruthy();
});

SpecEnd
