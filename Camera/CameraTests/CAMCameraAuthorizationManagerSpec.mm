// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMCameraAuthorizationManager.h"

#import "CAMCameraAuthorizer.h"

SpecBegin(CAMCameraAuthorizationManager)

__block CAMCameraAuthorizationManager *manager;
__block CAMCameraAuthorizer *authorizer;

beforeEach(^{
  authorizer = OCMClassMock([CAMCameraAuthorizer class]);
  manager = [[CAMCameraAuthorizationManager alloc] initWithCameraAuthorizer:authorizer];
});

it(@"should request authorization if authorization status is undetermined", ^{
  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusNotDetermined);
  [[manager requestAuthorization] subscribeNext:^(id) {}];
  OCMVerify([authorizer requestAuthorization:OCMOCK_ANY]);
});

it(@"should send updates correctly when authorization status changes", ^{
  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusAuthorized);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@YES, nil])]);
  expect([manager requestAuthorization]).to.sendValues(@[@(AVAuthorizationStatusAuthorized)]);

  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusDenied);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@NO, nil])]);
  expect([manager requestAuthorization]).to.sendValues(@[@(AVAuthorizationStatusDenied)]);

  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusRestricted);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@NO, nil])]);
  expect([manager requestAuthorization]).to.sendValues(@[@(AVAuthorizationStatusRestricted)]);
});

it(@"should update property when authorization status changes", ^{
  LLSignalTestRecorder *recorder = [RACObserve(manager, authorizationStatus) testRecorder];

  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusAuthorized);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@YES, nil])]);
  [[manager requestAuthorization] subscribeNext:^(id) {}];

  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusDenied);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@NO, nil])]);
  [[manager requestAuthorization] subscribeNext:^(id) {}];

  OCMExpect([authorizer authorizationStatus]).andReturn(AVAuthorizationStatusRestricted);
  OCMExpect([authorizer requestAuthorization:([OCMArg invokeBlockWithArgs:@NO, nil])]);
  [[manager requestAuthorization] subscribeNext:^(id) {}];

  expect(recorder).to.sendValues(@[
    @(AVAuthorizationStatusNotDetermined),
    @(AVAuthorizationStatusAuthorized),
    @(AVAuthorizationStatusDenied),
    @(AVAuthorizationStatusRestricted)
  ]);
});

SpecEnd
