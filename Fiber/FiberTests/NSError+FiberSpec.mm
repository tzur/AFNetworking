// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Fiber.h"

#import "FBRHTTPRequest.h"

SpecBegin(NSError_Fiber)

it(@"should create an error with the specified code and HTTP request", ^{
  FBRHTTPRequest *request =
      [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                   method:$(FBRHTTPRequestMethodGet)];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:request underlyingError:nil];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.equal(request);
  expect(error.lt_underlyingError).to.beNil();
});

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

it(@"should create an error with the specified code, HTTP request and response", ^{
  FBRHTTPRequest *request =
      [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                   method:$(FBRHTTPRequestMethodGet)];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200
                                                           HTTPVersion:nil headerFields:nil];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:request HTTPResponse:response
                              underlyingError:nil];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.equal(request);
  expect(error.fbr_HTTPResponse).to.equal(response);
  expect(error.lt_underlyingError).to.beNil();
});

it(@"should create an error with the specified code, HTTP request and response", ^{
  FBRHTTPRequest *request =
      [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                   method:$(FBRHTTPRequestMethodGet)];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200
                                                           HTTPVersion:nil headerFields:nil];
  NSError *underlyingError = [NSError errorWithDomain:@"Foo" code:1 userInfo:nil];
  NSError *error = [NSError fbr_errorWithCode:1337 HTTPRequest:request HTTPResponse:response
                              underlyingError:underlyingError];

  expect(error.lt_isLTDomain).to.beTruthy();
  expect(error.code).to.equal(1337);
  expect(error.fbr_HTTPRequest).to.equal(request);
  expect(error.fbr_HTTPResponse).to.equal(response);
  expect(error.lt_underlyingError).to.equal(underlyingError);
});

SpecEnd
