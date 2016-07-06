// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPClient.h"

#import <LTKit/NSError+LTKit.h>

#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"
#import "FBRHTTPSession.h"
#import "FBRHTTPTaskProgress.h"
#import "NSErrorCodes+Fiber.h"

/// Block used as a completion handler with a boolean \c finished parameter.
typedef RACSignal *(^FBRHTTPClientRequestInitiator)
    (FBRHTTPClient *client, NSString *URLString, FBRHTTPRequestParameters * _Nullable parameters);

NSString * const kFBRHTTPClientRequestExamples = @"FBRHTTPClientRequestExamples";
NSString * const kFBRHTTPClientExpectedMethod = @"FBRHTTPClientExpectedMethod";
NSString * const kFBRHTTPClientRequestInitiator = @"FBRHTTPClientRequestInitiator";

SpecBegin(FBRHTTPClient)

sharedExamplesFor(kFBRHTTPClientRequestExamples, ^(NSDictionary *data) {
  // Extracted from the data dictionary.
  __block FBRHTTPClientRequestInitiator requestInitiator;
  __block FBRHTTPRequestMethod *method;

  // Initialized by the shared examples.
  __block FBRHTTPClient *client;
  __block id session;
  __block id task;
  __block NSURL *URL;

  beforeEach(^{
    method = data[kFBRHTTPClientExpectedMethod];
    requestInitiator = data[kFBRHTTPClientRequestInitiator];

    session = OCMStrictProtocolMock(@protocol(FBRHTTPSession));
    task = OCMClassMock([NSURLSessionDataTask class]);
    client = [[FBRHTTPClient alloc] initWithSession:session baseURL:nil];
    URL = [NSURL URLWithString:@"http://foo.bar/index.html"];
  });

  it(@"should return a signal", ^{
    RACSignal *signal = requestInitiator(client, URL.absoluteString, nil);
    expect(signal).to.beKindOf([RACSignal class]);
  });

  it(@"should raise exception if the URL string is invalid", ^{
    expect(^{
      requestInitiator(client, @"/foo/bar", nil);
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should send a request to the session when subscribed to", ^{
    FBRHTTPRequestParameters *parameters = @{@"Foo": @"Bar"};
    FBRHTTPRequest *expectedRequest =
        [[FBRHTTPRequest alloc] initWithURL:URL method:method parameters:parameters
                         parametersEncoding:nil headers:nil];
    RACSignal *signal = requestInitiator(client, URL.absoluteString, parameters);
    OCMExpect([session dataTaskWithRequest:expectedRequest progress:OCMOCK_ANY success:OCMOCK_ANY
                                   failure:OCMOCK_ANY]).andReturn(task);

    [signal subscribeNext:^(id) {}];
    OCMVerifyAll(session);
  });

  it(@"should forward progress values when reported by the session", ^{
    NSProgress *progress = [NSProgress progressWithTotalUnitCount:100];
    __block FBRHTTPTaskProgressBlock progressBlock;
    OCMStub([session dataTaskWithRequest:OCMOCK_ANY progress:[OCMArg checkWithBlock:^BOOL(id obj) {
      progressBlock = obj;
      return obj != nil;
    }] success:OCMOCK_ANY failure:OCMOCK_ANY]).andReturn(task);

    LLSignalTestRecorder *recorder =
        [requestInitiator(client, URL.absoluteString, nil) testRecorder];

    expect(progressBlock).toNot.beNil();
    progress.completedUnitCount = 0;
    progressBlock(progress);
    progress.completedUnitCount = 50;
    progressBlock(progress);
    progress.completedUnitCount = 100;
    progressBlock(progress);

    expect(recorder).to.sendValues(@[
      [[FBRHTTPTaskProgress alloc] initWithProgress:0],
      [[FBRHTTPTaskProgress alloc] initWithProgress:0.5],
      [[FBRHTTPTaskProgress alloc] initWithProgress:1]
    ]);
    expect(recorder).toNot.complete();
  });

  it(@"should forward server response when reported by the session", ^{
    id responseMetadata = OCMClassMock([NSHTTPURLResponse class]);
    FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                  content:nil];
    OCMStub([session dataTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY
                                 success:([OCMArg invokeBlockWithArgs:response, nil])
                                 failure:OCMOCK_ANY]).andReturn(task);

    LLSignalTestRecorder *recorder =
        [requestInitiator(client, URL.absoluteString, nil) testRecorder];

    FBRHTTPTaskProgress *progress = [[FBRHTTPTaskProgress alloc] initWithResponse:response];
    expect(recorder).to.sendValues(@[progress]);
    expect(recorder).to.complete();
  });

  it(@"should err when session reports an error", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([session dataTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY
                                 failure:([OCMArg invokeBlockWithArgs:error, nil])])
        .andReturn(task);

    LLSignalTestRecorder *recorder =
        [requestInitiator(client, URL.absoluteString, nil) testRecorder];

    expect(recorder).to.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == 1337;
    });
  });

  it(@"should cancel the task when unsubscribed", ^{
    OCMExpect([task cancel]);
    OCMStub([session dataTaskWithRequest:OCMOCK_ANY progress:OCMOCK_ANY success:OCMOCK_ANY
                                 failure:OCMOCK_ANY]).andReturn(task);

    [[requestInitiator(client, URL.absoluteString, nil) subscribeNext:^(id) {}] dispose];

    OCMVerifyAll(task);
  });
});

context(@"initialization", ^{
  it(@"should initialize with the given session object and nil base URL", ^{
    id session = OCMProtocolMock(@protocol(FBRHTTPSession));
    FBRHTTPClient *client = [[FBRHTTPClient alloc] initWithSession:session baseURL:nil];

    expect(client.session).to.beIdenticalTo(session);
    expect(client.baseURL).to.beNil();
  });

  it(@"should initialize with the given session and base URL", ^{
    id session = OCMProtocolMock(@protocol(FBRHTTPSession));
    NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar/baz"];
    FBRHTTPClient *client = [[FBRHTTPClient alloc] initWithSession:session baseURL:baseURL];

    expect(client.session).to.beIdenticalTo(session);
    expect(client.baseURL).to.equal(baseURL);
  });

  it(@"should raise exception if base URL specifies unsupported protocol", ^{
    id session = OCMProtocolMock(@protocol(FBRHTTPSession));
    NSURL *baseURL = [NSURL URLWithString:@"ftp://foo.bar/baz"];

    expect(^{
      FBRHTTPClient __unused *client =
          [[FBRHTTPClient alloc] initWithSession:session baseURL:baseURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if base URL specifies fragment", ^{
    id session = OCMProtocolMock(@protocol(FBRHTTPSession));
    NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar/index.html#baz"];

    expect(^{
      FBRHTTPClient __unused *client =
          [[FBRHTTPClient alloc] initWithSession:session baseURL:baseURL];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise exception if base URL specifies query string", ^{
    id session = OCMProtocolMock(@protocol(FBRHTTPSession));
    NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar/index.html?bar=baz"];

    expect(^{
      FBRHTTPClient __unused *client =
          [[FBRHTTPClient alloc] initWithSession:session baseURL:baseURL];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"HTTP requests", ^{
  context(@"GET", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodGet),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client GET:URLString withParameters:parameters];
          }
    });
  });

  context(@"HEAD", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodHead),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client HEAD:URLString withParameters:parameters];
          }
    });
  });

  context(@"POST", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodPost),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client POST:URLString withParameters:parameters];
          }
    });
  });

  context(@"PUT", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodPut),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client PUT:URLString withParameters:parameters];
          }
    });
  });

  context(@"PATCH", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodPatch),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client PATCH:URLString withParameters:parameters];
          }
    });
  });

  context(@"DELETE", ^{
    itShouldBehaveLike(kFBRHTTPClientRequestExamples, @{
      kFBRHTTPClientExpectedMethod: $(FBRHTTPRequestMethodDelete),
      kFBRHTTPClientRequestInitiator:
          ^RACSignal *(FBRHTTPClient *client, NSString *URLString,
                       FBRHTTPRequestParameters * _Nullable parameters) {
            return [client DELETE:URLString withParameters:parameters];
          }
    });
  });
});

SpecEnd
