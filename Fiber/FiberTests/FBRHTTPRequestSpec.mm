// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPRequest.h"

#pragma mark -
#pragma mark FBRHTTPRequestMethod
#pragma mark -

SpecBegin(FBRHTTPRequestMethod)

it(@"should provide HTTP method string for every enum value", ^{
  [FBRHTTPRequestMethod enumerateEnumUsingBlock:^(FBRHTTPRequestMethod * _Nonnull value) {
    expect(value.HTTPMethod).toNot.beNil();
  }];
});

SpecEnd

SpecBegin(FBRHTTPRequest)

context(@"convenience initializer", ^{
  it(@"should initialize with the given URL string and HTTP method", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequestMethod *method = $(FBRHTTPRequestMethodGet);
    FBRHTTPRequest *request = [[FBRHTTPRequest alloc] initWithURL:URL method:method];

    expect(request.URL).to.equal(URL);
    expect(request.method).to.equal(method);
    expect(request.parameters).to.beNil();
    expect(request.parametersEncoding).to.beNil();
    expect(request.headers).to.beNil();
  });
});

context(@"designated initializer", ^{
  it(@"should initialize with the given parameters", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequestMethod *method = $(FBRHTTPRequestMethodGet);
    FBRHTTPRequestParameters *parameters = @{@"Foo": @"Bar"};
    FBRHTTPRequestParametersEncoding *parametersEncoding =
        [FBRHTTPRequestParametersEncoding enumWithValue:FBRHTTPRequestParametersEncodingJSON];
    FBRHTTPRequestHeaders *headers = @{@"Content-Type": @"application/json"};
    FBRHTTPRequest *request = [[FBRHTTPRequest alloc] initWithURL:URL method:method
                                                       parameters:parameters
                                               parametersEncoding:parametersEncoding
                                                          headers:headers];

    expect(request.URL).to.equal(URL);
    expect(request.method).to.equal(method);
    expect(request.parameters).to.equal(parameters);
    expect(request.parametersEncoding).to.equal(parametersEncoding);
    expect(request.headers).to.equal(headers);
  });
});

context(@"equality", ^{
  it(@"should inidcate that two identical objects are equal", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodGet)];
    FBRHTTPRequest *anotherRequest =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodGet)];

    expect(request).to.equal(anotherRequest);
  });

  it(@"should return the same hash for identical objects", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodGet)];
    FBRHTTPRequest *anotherRequest =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodGet)];

    expect(request.hash).to.equal(anotherRequest.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    NSURL *anotherURL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodGet)];
    FBRHTTPRequest *anotherRequest =
        [[FBRHTTPRequest alloc] initWithURL:anotherURL method:$(FBRHTTPRequestMethodPost)];

    expect([request isEqual:anotherRequest]).to.beFalsy();
  });
});

context(@"copying", ^{
  it(@"return a copy identical to the receiver", ^{
    NSURL *URL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequest *request =
        [[FBRHTTPRequest alloc] initWithURL:URL method:$(FBRHTTPRequestMethodPut)];
    FBRHTTPRequest *requestCopy = [request copy];

    expect(requestCopy).to.equal(request);
  });
});

SpecEnd
