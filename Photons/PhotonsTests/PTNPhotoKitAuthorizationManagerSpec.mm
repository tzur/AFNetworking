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
  manager = [[PTNPhotoKitAuthorizationManager alloc] initWithPhotoKitAuthorizer:authorizer];
  viewController = OCMClassMock([UIViewController class]);
});

it(@"should request authorization from PhotoKit if authorization status is undetermined", ^{
  OCMExpect([authorizer requestAuthorization:OCMOCK_ANY]);
  [[manager requestAuthorizationFromViewController:viewController]
      subscribeNext:^(id __unused x) {}];

  OCMVerifyAll((id)authorizer);
});

it(@"should send updates correctly when authorization status changes", ^{
  OCMStub([authorizer authorizationStatus]).andReturn(PHAuthorizationStatusNotDetermined);
  
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

SpecEnd
