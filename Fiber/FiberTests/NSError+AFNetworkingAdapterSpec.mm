// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+AFNetworkingAdapter.h"

#import <AFNetworking/AFNetworking.h>

#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

SpecBegin(NSError_AFNetworkingAdapter)

__block FBRHTTPRequest *request;
__block FBRHTTPResponse *response;

beforeEach(^{
  request = [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                         method:$(FBRHTTPRequestMethodGet)];
  NSHTTPURLResponse *responseMetadata =
      [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1"
                                headerFields:nil];
  response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata content:nil];
});

it(@"should correctly convert bad status code errors", ^{
  NSError *underlyingError = [NSError errorWithDomain:AFURLResponseSerializationErrorDomain
                                                 code:NSURLErrorBadServerResponse
                                             userInfo:@{@"Foo": @"Bar"}];
  NSError *fiberError = [underlyingError fbr_fiberErrorWithRequest:request response:response];

  expect(fiberError.domain).to.equal(kLTErrorDomain);
  expect(fiberError.code).to.equal(FBRErrorCodeHTTPUnsuccessfulResponseReceived);
  expect(fiberError.fbr_HTTPRequest).to.equal(request);
  expect(fiberError.fbr_HTTPResponse).to.equal(response);
  expect(fiberError.lt_underlyingError).to.equal(underlyingError);
});

it(@"should correctly convert data decoding errors", ^{
  NSError *underlyingError = [NSError errorWithDomain:AFURLResponseSerializationErrorDomain
                                                 code:NSURLErrorCannotDecodeContentData
                                             userInfo:@{@"Foo": @"Bar"}];
  NSError *fiberError = [underlyingError fbr_fiberErrorWithRequest:request response:response];

  expect(fiberError.domain).to.equal(kLTErrorDomain);
  expect(fiberError.code).to.equal(FBRErrorCodeHTTPResponseDeserializationFailed);
  expect(fiberError.fbr_HTTPRequest).to.equal(request);
  expect(fiberError.fbr_HTTPResponse).to.equal(response);
  expect(fiberError.lt_underlyingError).to.equal(underlyingError);
});

it(@"should correctly convert cancellation errors", ^{
  NSError *underlyingError = [NSError errorWithDomain:@"FooBar" code:NSURLErrorCancelled
                                             userInfo:@{@"Foo": @"Bar"}];
  NSError *fiberError = [underlyingError fbr_fiberErrorWithRequest:request response:response];

  expect(fiberError.domain).to.equal(kLTErrorDomain);
  expect(fiberError.code).to.equal(FBRErrorCodeHTTPTaskCancelled);
  expect(fiberError.fbr_HTTPRequest).to.equal(request);
  expect(fiberError.fbr_HTTPResponse).to.equal(response);
  expect(fiberError.lt_underlyingError).to.equal(underlyingError);
});

it(@"should fallback to generic failure error for unknown errors", ^{
  NSError *underlyingError = [NSError errorWithDomain:@"FooBar" code:NSURLErrorCannotFindHost
                                             userInfo:@{@"Foo": @"Bar"}];
  NSError *fiberError = [underlyingError fbr_fiberErrorWithRequest:request response:response];

  expect(fiberError.domain).to.equal(kLTErrorDomain);
  expect(fiberError.code).to.equal(FBRErrorCodeHTTPTaskFailed);
  expect(fiberError.fbr_HTTPRequest).to.equal(request);
  expect(fiberError.fbr_HTTPResponse).to.equal(response);
  expect(fiberError.lt_underlyingError).to.equal(underlyingError);
});

SpecEnd
