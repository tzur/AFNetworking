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

context(@"data transmission direction", ^{
  NSArray<FBRHTTPRequestMethod *> * const kDownloadMethods = @[$(FBRHTTPRequestMethodGet)];
  NSArray<FBRHTTPRequestMethod *> * const kUploadMethods = @[
    $(FBRHTTPRequestMethodPost),
    $(FBRHTTPRequestMethodPut),
    $(FBRHTTPRequestMethodPatch)
  ];

  it(@"should correctly indicate data transmission direction for all methods", ^{
    [FBRHTTPRequestMethod enumerateEnumUsingBlock:^(FBRHTTPRequestMethod *value) {
      expect(value.downloadsData).to.equal([kDownloadMethods containsObject:value]);
      expect(value.uploadsData).to.equal([kUploadMethods containsObject:value]);
    }];
  });
});

SpecEnd

SpecBegin(FBRHTTPRequest)

context(@"supported protocols", ^{
  it(@"should indicate that HTTP and HTTPS protocols are supported", ^{
    expect([FBRHTTPRequest isProtocolSupported:[NSURL URLWithString:@"http://foo.bar"]])
        .to.beTruthy();
    expect([FBRHTTPRequest isProtocolSupported:[NSURL URLWithString:@"https://foo.bar"]])
        .to.beTruthy();
  });

  it(@"should indicate that non HTTP protocols are not supported", ^{
    expect([FBRHTTPRequest isProtocolSupported:[NSURL URLWithString:@"ftp://foo.bar"]])
        .to.beFalsy();
    expect([FBRHTTPRequest isProtocolSupported:[NSURL URLWithString:@"smtp://foo.bar"]])
        .to.beFalsy();
  });
});

context(@"convenience initializer", ^{
  it(@"should initialize with the given URL and HTTP method", ^{
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

  it(@"should raise exception if protocol is not supported", ^{
    NSURL *URL = [NSURL URLWithString:@"ftp://foo.bar"];
    FBRHTTPRequestMethod *method = $(FBRHTTPRequestMethodGet);

    expect(^{
      FBRHTTPRequest __unused *request =
          [[FBRHTTPRequest alloc] initWithURL:URL method:method parameters:nil
                           parametersEncoding:nil headers:nil];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should initialize successfully if protocol is HTTPS", ^{
    NSURL *URL = [NSURL URLWithString:@"https://foo.bar"];
    FBRHTTPRequestMethod *method = $(FBRHTTPRequestMethodGet);
    FBRHTTPRequest *request =
          [[FBRHTTPRequest alloc] initWithURL:URL method:method parameters:nil
                           parametersEncoding:nil headers:nil];

    expect(request.URL).to.equal(URL);
    expect(request.method).to.equal(method);
  });
});

context(@"equality", ^{
  it(@"should indicate that two identical objects are equal", ^{
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
