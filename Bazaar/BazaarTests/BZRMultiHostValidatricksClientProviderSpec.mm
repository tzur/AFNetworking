// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRMultiHostValidatricksClientProvider.h"

#import <Fiber/FBRHTTPClient.h>

SpecBegin(BZRMultiHostValidatricksClientProvider)

context(@"one client provider", ^{
  it(@"should return same HTTP client if only one client provider supplied", ^{
    FBRHTTPClient *client = OCMClassMock([FBRHTTPClient class]);
    id<FBRHTTPClientProvider> clientProvider = OCMProtocolMock(@protocol(FBRHTTPClientProvider));
    OCMStub([clientProvider HTTPClient]).andReturn(client);

    BZRMultiHostValidatricksClientProvider *multiClientsProvider =
        [[BZRMultiHostValidatricksClientProvider alloc] initWithClientProviders:@[clientProvider]];

    expect([multiClientsProvider HTTPClient]).to.equal(client);
    expect([multiClientsProvider HTTPClient]).to.equal(client);
  });
});

context(@"two clients providers", ^{
  __block FBRHTTPClient* firstClient;
  __block FBRHTTPClient* secondClient;
  __block BZRMultiHostValidatricksClientProvider *multiClientsProvider;

  beforeEach(^{
    firstClient = OCMClassMock([FBRHTTPClient class]);
    id<FBRHTTPClientProvider> firstClientProvider =
        OCMProtocolMock(@protocol(FBRHTTPClientProvider));
    OCMStub([firstClientProvider HTTPClient]).andReturn(firstClient);

    secondClient = OCMClassMock([FBRHTTPClient class]);
    id<FBRHTTPClientProvider> secondClientProvider =
        OCMProtocolMock(@protocol(FBRHTTPClientProvider));
    OCMStub([secondClientProvider HTTPClient]).andReturn(secondClient);

    multiClientsProvider = [[BZRMultiHostValidatricksClientProvider   alloc]
         initWithClientProviders:@[firstClientProvider, secondClientProvider]];
  });

  it(@"should return HTTP clients according to supplied client provider order", ^{
    expect([multiClientsProvider HTTPClient]).to.equal(firstClient);
    expect([multiClientsProvider HTTPClient]).to.equal(secondClient);
  });

  it(@"should return first HTTP client after end of client providers", ^{
    expect([multiClientsProvider HTTPClient]).to.equal(firstClient);
    expect([multiClientsProvider HTTPClient]).to.equal(secondClient);
    expect([multiClientsProvider HTTPClient]).to.equal(firstClient);
  });
});

SpecEnd
