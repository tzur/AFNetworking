// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Fiber.h"

#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"

SpecBegin(NSError_Fiber)

it(@"should create an error with the specified code, HTTP request and underlying error", ^{
  FBRHTTPRequest *request =
      [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                   method:$(FBRHTTPRequestMethodGet)];
  NSError *underlyingError = [NSError errorWithDomain:@"Foo" code:1 userInfo:nil];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:request
                              underlyingError:underlyingError];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.equal(request);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with the specified code and parameters", ^{
  FBRHTTPRequest *request =
      [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                   method:$(FBRHTTPRequestMethodGet)];
  FBRHTTPResponse *response =
      [[FBRHTTPResponse alloc] initWithMetadata:OCMClassMock([NSHTTPURLResponse class])
                                        content:nil];
  NSError *underlyingError = [NSError errorWithDomain:@"Foo" code:1 userInfo:nil];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:request HTTPResponse:response
                              underlyingError:underlyingError];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.equal(request);
  expect(error.fbr_HTTPResponse).to.equal(response);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

it(@"should create an error with the specified code and without request or response", ^{
  NSError *underlyingError = [NSError errorWithDomain:@"Foo" code:1 userInfo:nil];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:nil HTTPResponse:nil
                              underlyingError:underlyingError];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.beNil();
  expect(error.fbr_HTTPResponse).to.beNil();
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

SpecEnd
