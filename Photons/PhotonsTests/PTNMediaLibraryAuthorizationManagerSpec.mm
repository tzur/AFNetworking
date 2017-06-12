// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "PTNMediaLibraryAuthorizationManager.h"

#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNMediaLibraryAuthorizer.h"

SpecBegin(PTNMediaLibraryAuthorizationManager)

__block PTNMediaLibraryAuthorizationManager *manager;
__block PTNMediaLibraryAuthorizer *authorizer;
__block UIViewController *viewController;

beforeEach(^{
  authorizer = OCMClassMock([PTNMediaLibraryAuthorizer class]);
  OCMStub([authorizer authorizationStatus])
      .andReturn(MPMediaLibraryAuthorizationStatusNotDetermined);
  manager = [[PTNMediaLibraryAuthorizationManager alloc] initWithAuthorizer:authorizer];
  viewController = [[UIViewController alloc] init];
});

it(@"should request authorization from Media Library if authorization status is undetermined", ^{
  [[manager requestAuthorizationFromViewController:viewController]
      subscribeNext:^(id) {}];
  OCMVerify([authorizer requestAuthorization:OCMOCK_ANY]);
});

it(@"should send updates when authorization status changes", ^{
  OCMExpect([authorizer requestAuthorization:
             ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusAuthorized), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);

  OCMExpect([authorizer requestAuthorization:
             ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusDenied), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusDenied)]);

  OCMExpect([authorizer requestAuthorization:
             ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusRestricted), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusRestricted)]);
});

it(@"should update property when authorization status changes", ^{
  LLSignalTestRecorder *recorder = [RACObserve(manager, authorizationStatus) testRecorder];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusAuthorized), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusDenied), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(MPMediaLibraryAuthorizationStatusRestricted), nil])]);
  [[manager requestAuthorizationFromViewController:viewController] subscribeNext:^(id) {}];

  expect(recorder).to.sendValues(@[
    $(PTNAuthorizationStatusNotDetermined),
    $(PTNAuthorizationStatusAuthorized),
    $(PTNAuthorizationStatusDenied),
    $(PTNAuthorizationStatusRestricted)
  ]);
});

SpecEnd
