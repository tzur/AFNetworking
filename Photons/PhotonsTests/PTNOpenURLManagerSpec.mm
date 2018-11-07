// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNOpenURLManager.h"

SpecBegin(PTNOpenURLManager)

__block PTNOpenURLManager *manager;
__block UIApplication *app;
__block NSURL *url;

__block id firstHandler;
__block id secondHandler;
__block id thirdHandler;

beforeEach(^{
  firstHandler = OCMProtocolMock(@protocol(PTNOpenURLHandler));
  secondHandler = OCMProtocolMock(@protocol(PTNOpenURLHandler));
  thirdHandler = OCMProtocolMock(@protocol(PTNOpenURLHandler));

  manager = [[PTNOpenURLManager alloc] initWithHandlers:@[
    firstHandler,
    secondHandler,
    thirdHandler
  ]];

  app = OCMClassMock([UIApplication class]);
  url = [NSURL URLWithString:@"http://www.foo.com"];
});

it(@"should call resonders until one handles the url", ^{
  OCMExpect([firstHandler application:OCMOCK_ANY openURL:OCMOCK_ANY options:OCMOCK_ANY])
      .andReturn(NO);
  OCMExpect([secondHandler application:OCMOCK_ANY openURL:OCMOCK_ANY options:OCMOCK_ANY])
      .andReturn(YES);
  [[thirdHandler reject] application:OCMOCK_ANY openURL:OCMOCK_ANY options:OCMOCK_ANY];
  [manager application:app openURL:url options:nil];
});

it(@"should handle url if any the registered handlers handles the url", ^{
  OCMExpect([firstHandler application:OCMOCK_ANY openURL:OCMOCK_ANY options:OCMOCK_ANY])
      .andReturn(YES);

  expect([manager application:app openURL:url options:nil]).to.beTruthy();
});

it(@"should not handle url if none of the registered Handlers handles the url", ^{
  expect([manager application:app openURL:url options:nil]).to.beFalsy();
});

SpecEnd
