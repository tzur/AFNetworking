// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPResponse.h"

#import "NSErrorCodes+Fiber.h"

#pragma mark -
#pragma mark FBRHTTPResponse Specs
#pragma mark -

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

#pragma mark -
#pragma mark FBRHTTPResponse+JSONDeserialization Specs
#pragma mark -

SpecBegin(FBRHTTPResponse_JSONDeserialization)

__block NSURL *URL;
__block NSHTTPURLResponse *responseMetadata;

beforeEach(^{
  URL = [NSURL URLWithString:@"http://foo.bar"];
  responseMetadata =
      [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:nil headerFields:nil];
});

it(@"should successfully deserialize JSON array", ^{
  auto responseContent = [@"[1, 2, \"3\"]" dataUsingEncoding:NSUTF8StringEncoding];
  auto response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                    content:responseContent];

  NSError *error;
  id deserializedContent = [response deserializeJSONContentWithError:&error];

  expect(error).to.beNil();
  expect(deserializedContent).to.equal(@[@1, @2, @"3"]);
});

it(@"should successfully deserialize JSON object", ^{
  auto responseContent = [@"{\"foo\": \"bar\"}" dataUsingEncoding:NSUTF8StringEncoding];
  auto response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                    content:responseContent];

  NSError *error;
  id deserializedContent = [response deserializeJSONContentWithError:&error];

  expect(error).to.beNil();
  expect(deserializedContent).to.equal(@{@"foo": @"bar"});
});

it(@"should fail if response content is nil", ^{
  auto response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata content:nil];

  NSError *error;
  id deserializedContent = [response deserializeJSONContentWithError:&error];

  expect(error.code).to.equal(FBRErrorCodeJSONDeserializationFailed);
  expect(deserializedContent).to.beNil();
});

it(@"should fail if response content is not a valid JSON", ^{
  auto responseContent = [@"foo-bar" dataUsingEncoding:NSUTF8StringEncoding];
  auto response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                    content:responseContent];

  NSError *error;
  id deserializedContent = [response deserializeJSONContentWithError:&error];

  expect(error.code).to.equal(FBRErrorCodeJSONDeserializationFailed);
  expect(error.lt_underlyingError).toNot.beNil();
  expect(deserializedContent).to.beNil();
});

SpecEnd
