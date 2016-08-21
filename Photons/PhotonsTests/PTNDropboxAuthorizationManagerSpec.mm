// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNDropboxAuthorizationManager.h"

#import <DropboxSDK/DropboxSDK.h>

#import "DBSession+RACSignalSupport.h"
#import "NSError+Photons.h"
#import "PTNAuthorizationStatus.h"
#import "PTNOpenURLManager.h"

SpecBegin(PTNDropboxAuthorizationManager)

__block PTNDropboxAuthorizationManager *manager;
__block id dbSession;
__block UIViewController *viewController;

beforeEach(^{
  dbSession = OCMClassMock([DBSession class]);
  manager = [[PTNDropboxAuthorizationManager alloc] initWithDropboxSession:dbSession];
  viewController = OCMClassMock([UIViewController class]);
});

it(@"should return immediately if session is already linked", ^{
  OCMStub([dbSession isLinked]).andReturn(YES);
  expect([manager requestAuthorizationFromViewController:viewController])
      .to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);
});

it(@"should reqest access from dropbox if session isn't linked", ^{
  OCMStub([dbSession isLinked]).andReturn(NO);
  OCMExpect([dbSession linkFromController:viewController]);

  [[manager requestAuthorizationFromViewController:viewController]
      subscribeNext:^(id __unused x) {}];

  OCMVerifyAll(dbSession);
});

context(@"openURL handling", ^{
  __block UIApplication *app;
  __block NSURL *url;

  beforeEach(^{
    app = OCMClassMock([UIApplication class]);
    url = [NSURL URLWithString:@"http://www.foo.com"];
  });

  it(@"should correctly interperet dropbox openURL request as authorized", ^{
    OCMStub([dbSession handleOpenURL:url]).andReturn(YES);

    OCMExpect([dbSession isLinked]).andReturn(NO);
    LLSignalTestRecorder *values = [[manager requestAuthorizationFromViewController:viewController]
                                    testRecorder];

    OCMExpect([dbSession isLinked]).andReturn(YES);
    [manager application:app openURL:url options:nil];

    expect(values).to.sendValues(@[$(PTNAuthorizationStatusAuthorized)]);
    expect(manager.authorizationStatus).to.equal($(PTNAuthorizationStatusAuthorized));
  });

  it(@"should correctly interperet dropbox openURL request as undetermiend", ^{
    OCMStub([dbSession handleOpenURL:url]).andReturn(YES);

    OCMExpect([dbSession isLinked]).andReturn(NO);
    LLSignalTestRecorder *values = [[manager requestAuthorizationFromViewController:viewController]
                                    testRecorder];

    OCMExpect([dbSession isLinked]).andReturn(NO);
    [manager application:app openURL:url options:nil];

    expect(values).to.sendValues(@[$(PTNAuthorizationStatusNotDetermined)]);
    expect(manager.authorizationStatus).to.equal($(PTNAuthorizationStatusNotDetermined));
  });

  it(@"should not claim to handle unsupported URLs", ^{
    OCMStub([dbSession handleOpenURL:url]).andReturn(NO);

    expect([manager application:app openURL:url options:nil]).to.beFalsy();
  });
  
  it(@"should update internal state as authorization status changes", ^{
    OCMStub([dbSession handleOpenURL:url]).andReturn(YES);
    LLSignalTestRecorder *recorder = [RACObserve(manager, authorizationStatus) testRecorder];

    OCMExpect([dbSession isLinked]).andReturn(NO);
    [manager application:app openURL:url options:nil];

    OCMExpect([dbSession isLinked]).andReturn(YES);
    [manager application:app openURL:url options:nil];

    expect(recorder).to.sendValues(@[
      $(PTNAuthorizationStatusNotDetermined),
      $(PTNAuthorizationStatusNotDetermined),
      $(PTNAuthorizationStatusAuthorized)
    ]);
  });
});

it(@"should return not determined status on authorization failure", ^{
  OCMExpect([dbSession isLinked]).andReturn(NO);
  LLSignalTestRecorder *recorder = [[manager requestAuthorizationFromViewController:viewController]
                                    testRecorder];

  [(id<DBSessionDelegate>)manager sessionDidReceiveAuthorizationFailure:dbSession userId:@"foo"];

  expect(recorder).to.sendValues(@[$(PTNAuthorizationStatusNotDetermined)]);
});

it(@"should revoke access", ^{
  OCMExpect([dbSession isLinked]).andReturn(YES);
  expect([manager requestAuthorizationFromViewController:viewController]).will.complete();
  expect(manager.authorizationStatus).to.equal($(PTNAuthorizationStatusAuthorized));

  OCMExpect([dbSession isLinked]).andReturn(NO);
  expect([manager revokeAuthorization]).to.complete();
  expect(manager.authorizationStatus).to.equal($(PTNAuthorizationStatusNotDetermined));
});

SpecEnd
