// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNPhotoKitAuthorizationManager.h"

#import "PTNPhotoKitAuthorizer.h"
#import "NSError+Photons.h"

SpecBegin(PTNPhotoKitAuthorizationManager)

__block PTNPhotoKitAuthorizationManager *manager;
__block id authorizer;
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

  OCMVerifyAll(authorizer);
});

it(@"should send updates correctly when authorization status changes", ^{
  OCMStub([authorizer authorizationStatus]).andReturn(PHAuthorizationStatusNotDetermined);
  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusAuthorized), nil])]);

  expect([manager requestAuthorizationFromViewController:viewController]).to.complete();

  OCMExpect([authorizer requestAuthorization:
      ([OCMArg invokeBlockWithArgs:@(PHAuthorizationStatusDenied), nil])]);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.matchError(^BOOL(NSError *error) {
    return error.code == PTNErrorCodeAuthorizationFailed;
  });
});

SpecEnd
