// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitAuthorizationManager.h"

#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNPhotoKitAuthorizer.h"

SpecBegin(PTNPhotoKitAuthorizationManager)

__block PTNPhotoKitAuthorizationManager *manager;
__block PTNPhotoKitAuthorizer *authorizer;
__block UIViewController *viewController;

beforeEach(^{
  authorizer = OCMClassMock([PTNPhotoKitAuthorizer class]);
  OCMStub([authorizer authorizationStatus]).andReturn(PHAuthorizationStatusNotDetermined);
  manager = [[PTNPhotoKitAuthorizationManager alloc] initWithPhotoKitAuthorizer:authorizer];
  viewController = OCMClassMock([UIViewController class]);
});

it(@"should request authorization from PhotoKit if authorization status is undetermined", ^{
  OCMExpect([authorizer requestAuthorization:OCMOCK_ANY]);
  [[manager requestAuthorizationFromViewController:viewController]
      subscribeNext:^(id __unused x) {}];

  OCMVerifyAll(authorizer);
});

it(@"should send updates correctly when authorization status changes", ^{
  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusAuthorized), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusDenied), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusDenied)]);

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusRestricted), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusRestricted)]);
});

it(@"should update property when authorization status changes", ^{
  LLSignalTestRecorder *recorder = [RACObserve(manager, authorizationStatus) testRecorder];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusAuthorized), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusDenied), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusRestricted), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  expect(recorder).to.sendValues(@[
    $(PTNAuthorizationStatusNotDetermined),
    $(PTNAuthorizationStatusAuthorized),
    $(PTNAuthorizationStatusDenied),
    $(PTNAuthorizationStatusRestricted)
  ]);
});

SpecEnd
