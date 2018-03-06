// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "RACSignal+BackgroundTask.h"

#import "NSErrorCodes+Intelligence.h"

SpecBegin(RACSignal_BackgroundTask)

__block UIApplication *application;

beforeEach(^{
  application = OCMClassMock(UIApplication.class);
});

it(@"should err if starting a background task is not possible.", ^{
  __block BOOL didCreateSideEffect = NO;
  auto signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber>) {
    didCreateSideEffect = YES;
    return nil;
  }];

  OCMStub([application beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY])
      .andReturn(UIBackgroundTaskInvalid);

  auto expectedError = [NSError lt_errorWithCode:INTErrorCodeBackgroundTaskFailedToStart];
  expect([RACSignal backgroundTaskWithSignalBlock:^{return signal;} application:application]).to
      .sendError(expectedError);
  expect(didCreateSideEffect).to.beFalsy();
});

it(@"should end background task when underlying signal completes", ^{
  auto taskIdentifier = 1337;
  OCMStub([application beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY])
      .andReturn(taskIdentifier);

  expect([RACSignal backgroundTaskWithSignalBlock:^{return [RACSignal empty];}
                                      application:application]).to.complete();
  OCMVerify([application endBackgroundTask:taskIdentifier]);
});

it(@"should not end background task if the underlying signal does not return", ^{
  auto taskIdentifier = 1337;
  OCMStub([application beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY])
      .andReturn(taskIdentifier);

  OCMReject([application endBackgroundTask:taskIdentifier]);
  expect([RACSignal backgroundTaskWithSignalBlock:^{return [RACSignal never];}
                                      application:application]).toNot.complete();
});

it(@"should dispose of underlying signal if task expires", ^{
  __block LTVoidBlock expirationHandler;
  auto taskIdentifier = 1337;
  OCMStub([application beginBackgroundTaskWithExpirationHandler:OCMOCK_ANY])
      .andDo(^(NSInvocation *invocation) {
        LTVoidBlock __unsafe_unretained handler;
        [invocation getArgument:&handler atIndex:2];
        expirationHandler = handler;
      }).andReturn(taskIdentifier);

  __block auto didDispose = NO;
  auto signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>) {
    return [RACDisposable disposableWithBlock:^{
      didDispose = YES;
    }];
  }];

  [[RACSignal backgroundTaskWithSignalBlock:^{return signal;} application:application]
   subscribeCompleted:^{}];
  expirationHandler();
  expect(didDispose).to.beTruthy();
  OCMVerify([application endBackgroundTask:taskIdentifier]);
});

SpecEnd
