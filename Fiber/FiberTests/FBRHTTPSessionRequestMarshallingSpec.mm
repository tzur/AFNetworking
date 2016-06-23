// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPSessionRequestMarshalling.h"

SpecBegin(FBRHTTPSessionRequestMarshalling)

context(@"defualt initializer", ^{
  it(@"should initialize with default properties values", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];

    expect(requestMarshalling).toNot.beNil();
    expect(requestMarshalling.parametersEncoding).
        to.equal($(FBRHTTPRequestParametersEncodingURLQuery));
    expect(requestMarshalling.baseURL).to.beNil();
    expect(requestMarshalling.headers).to.beNil();
  });
});

context(@"initializer with parameters", ^{
  it(@"should initialize with the given parameters", ^{
    FBRHTTPRequestParametersEncoding *parametersEncoding = $(FBRHTTPRequestParametersEncodingJSON);
    NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar"];
    FBRHTTPRequestHeaders *headers = @{@"Foo": @"Bar"};
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] initWithParametersEncoding:parametersEncoding
                                                                     baseURL:baseURL
                                                                     headers:headers];

    expect(requestMarshalling).toNot.beNil();
    expect(requestMarshalling.parametersEncoding).to.equal(parametersEncoding);
    expect(requestMarshalling.baseURL).to.equal(baseURL);
    expect(requestMarshalling.headers).to.equal(headers);
  });

  it(@"should allow base URL and headers to be nil", ^{
    FBRHTTPRequestParametersEncoding *parametersEncoding = $(FBRHTTPRequestParametersEncodingJSON);
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] initWithParametersEncoding:parametersEncoding
                                                                     baseURL:nil headers:nil];

    expect(requestMarshalling).toNot.beNil();
    expect(requestMarshalling.baseURL).to.beNil();
    expect(requestMarshalling.headers).to.beNil();
  });
});

context(@"equality", ^{
  it(@"should inidcate that two identical request marshalling are equal", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];
    FBRHTTPSessionRequestMarshalling *anotherRequestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];

    expect([requestMarshalling isEqual:anotherRequestMarshalling]).to.beTruthy();
  });

  it(@"should return the same hash for identical objects", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];
    FBRHTTPSessionRequestMarshalling *anotherRequestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];

    expect(requestMarshalling.hash).to.equal(anotherRequestMarshalling.hash);
  });

  it(@"should indicate that two non identical objects are not equal", ^{
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];
    FBRHTTPSessionRequestMarshalling *anotherRequestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc]
         initWithParametersEncoding:$(FBRHTTPRequestParametersEncodingJSON) baseURL:nil
         headers:@{}];

    expect([requestMarshalling isEqual:anotherRequestMarshalling]).to.beFalsy();
  });
});

SpecEnd
