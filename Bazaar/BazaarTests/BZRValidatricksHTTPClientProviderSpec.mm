// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRValidatricksHTTPClientProvider.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPSessionConfiguration.h>
#import <Fiber/FBRHTTPSessionConfigurationProvider.h>

SpecBegin(BZRValidatricksHTTPClientProvider)

context(@"getting HTTP clients", ^{
  __block id client;
  __block id<FBRHTTPSessionConfigurationProvider> configurationProvider;
  __block NSString *hostName;
  __block BZRValidatricksHTTPClientProvider *clientProvider;
  __block FBRHTTPSessionConfiguration *sessionConfiguration;

  beforeEach(^{
    client = OCMClassMock([FBRHTTPClient class]);
    configurationProvider = OCMProtocolMock(@protocol(FBRHTTPSessionConfigurationProvider));
    hostName = @"foo.bar";
    clientProvider =
        [[BZRValidatricksHTTPClientProvider alloc]
         initWithSessionConfigurationProvider:configurationProvider hostName:hostName];

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

  it(@"should return client with the server URL as baseURL", ^{
    OCMExpect([client clientWithSessionConfiguration:OCMOCK_ANY baseURL:clientProvider.serverURL]);

    [clientProvider HTTPClient];

    OCMVerifyAll(client);
  });

  it(@"should return client with the default server URL as baseURL", ^{
    clientProvider = [[BZRValidatricksHTTPClientProvider alloc] init];

    expect([clientProvider.serverURL.absoluteString hasPrefix:@"https://"]);
  });
});

SpecEnd
