// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPResponse.h"

SpecBegin(FBRHTTPResponse)

__block NSURL *URL;
__block NSHTTPURLResponse *responseMetadata;
__block NSData *responseContent;

beforeEach(^{
  URL = [NSURL URLWithString:@"http://foo.bar"];
  responseMetadata =
      [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:nil headerFields:nil];
  responseContent = [@"Foo Bar" dataUsingEncoding:NSUTF8StringEncoding];
});

context(@"initialization", ^{
  it(@"should initialize with the given response and response body", ^{
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:responseContent];

    expect(response.metadata).to.equal(responseMetadata);
    expect(response.content).to.equal(responseContent);
  });
});

context(@"equality", ^{
  it(@"should indicate that two identical objects are equal", ^{
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:responseContent];
    FBRHTTPResponse *anotherResponse = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                         content:responseContent];

    expect([response isEqual:anotherResponse]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:responseContent];
    FBRHTTPResponse *anotherResponse = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                         content:responseContent];

    expect(response.hash).to.equal(anotherResponse.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:responseContent];
    FBRHTTPResponse *anotherResponse = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                         content:nil];

    expect([response isEqual:anotherResponse]).to.beFalsy();
  });
});

context(@"copying", ^{
  it(@"should return a configuration identical to the copied configuration", ^{
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:responseContent];
    FBRHTTPResponse *responseCopy = [response copy];

    expect(response).to.equal(responseCopy);
  });
});

SpecEnd
