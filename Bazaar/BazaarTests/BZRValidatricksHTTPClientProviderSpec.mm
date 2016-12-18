// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatricksHTTPClientProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionConfigurationProvider.h>

SpecBegin(BZRValidatricksHTTPClientProvider)

context(@"default server URL", ^{
  it(@"should provide default server URL", ^{
    expect([BZRValidatricksHTTPClientProvider defaultValidatricksServerURL]).toNot.beNil();
  });
});

context(@"getting HTTP clients", ^{
  __block id client;
  __block id<FBRHTTPSessionConfigurationProvider> configurationProvider;
  __block NSURL *serverURL;
  __block BZRValidatricksHTTPClientProvider *clientProvider;
  __block FBRHTTPSessionConfiguration *sessionConfiguration;

  beforeEach(^{
    client = OCMClassMock([FBRHTTPClient class]);
    configurationProvider = OCMProtocolMock(@protocol(FBRHTTPSessionConfigurationProvider));
    serverURL = [NSURL URLWithString:@"foo/bar/"];
    clientProvider =
        [[BZRValidatricksHTTPClientProvider alloc]
         initWithSessionConfigurationProvider:configurationProvider serverURL:serverURL];

    sessionConfiguration = OCMClassMock([FBRHTTPSessionConfiguration class]);
    OCMStub([configurationProvider HTTPSessionConfiguration]).andReturn(sessionConfiguration);
  });

  afterEach(^{
    [client stopMocking];
  });

  it(@"should return client with session configuration provided by configuration provider", ^{
    OCMExpect([client clientWithSessionConfiguration:sessionConfiguration baseURL:OCMOCK_ANY]);

    [clientProvider HTTPClient];

    OCMVerifyAll(client);
  });

  it(@"should return client with the given server URL as baseURL", ^{
    OCMExpect([client clientWithSessionConfiguration:OCMOCK_ANY baseURL:serverURL]);

    [clientProvider HTTPClient];

    OCMVerifyAll(client);
  });

  it(@"should return client with the default server URL as baseURL", ^{
    clientProvider = [[BZRValidatricksHTTPClientProvider alloc] init];
    OCMExpect([client clientWithSessionConfiguration:OCMOCK_ANY
        baseURL:[BZRValidatricksHTTPClientProvider defaultValidatricksServerURL]]);

    [clientProvider HTTPClient];

    OCMVerifyAll(client);
  });
});

SpecEnd
