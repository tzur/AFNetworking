// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+Fiber.h"

#import "FBRHTTPResponse.h"
#import "FBRHTTPTaskProgress.h"
#import "NSErrorCodes+Fiber.h"

SpecBegin(RACSignal_Fiber)

context(@"deserialize JSON operator", ^{
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    subject = [RACSubject subject];
    recorder = [[subject fbr_deserializeJSON] testRecorder];
  });

  it(@"should raise exception if the signal sends unexpected values", ^{
    expect(^{
      [subject sendNext:@"foo"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should ignore incomplete progress values", ^{
    [subject sendNext:[[FBRHTTPTaskProgress alloc] init]];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithProgress:1]];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the deserialzied object", ^{
    NSDictionary *value = @{@"foo": @"bar"};
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:value options:0 error:nil];
    FBRHTTPResponse *response =
        [[FBRHTTPResponse alloc] initWithMetadata:OCMClassMock([NSHTTPURLResponse class])
                                          content:responseData];

    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithResponse:response]];

    expect(recorder).to.sendValues(@[value]);
    expect(recorder).toNot.complete();
  });

  it(@"should complete when the underlying signal completes", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err if the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.sendError(error);
  });

  it(@"should err if the response data is not a serialized JSON object", ^{
    NSString *value = @"foo bar";
    NSData *responseData = [value dataUsingEncoding:NSUTF8StringEncoding];
    FBRHTTPResponse *response =
        [[FBRHTTPResponse alloc] initWithMetadata:OCMClassMock([NSHTTPURLResponse class])
                                          content:responseData];

    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithResponse:response]];
    [subject sendCompleted];

    expect(recorder).to.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == FBRErrorCodeJSONDeserializationFailed;
    });
  });

  it(@"should err if the response contains no data", ^{
    FBRHTTPResponse *response =
        [[FBRHTTPResponse alloc] initWithMetadata:OCMClassMock([NSHTTPURLResponse class])
                                          content:nil];

    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithResponse:response]];
    [subject sendCompleted];

    expect(recorder).to.matchError(^BOOL(NSError *error) {
      return error.lt_isLTDomain && error.code == FBRErrorCodeJSONDeserializationFailed;
    });
  });
});

context(@"skip progress operator", ^{
  __block RACSubject *subject;
  __block LLSignalTestRecorder *recorder;

  beforeEach(^{
    subject = [RACSubject subject];
    recorder = [[subject fbr_skipProgress] testRecorder];
  });

  it(@"should raise exception if the signal sends unexpected values", ^{
    expect(^{
      [subject sendNext:@"foo"];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should ignore incomplete progress values", ^{
    [subject sendNext:[[FBRHTTPTaskProgress alloc] init]];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithProgress:1]];

    expect(recorder).to.sendValuesWithCount(0);
  });

  it(@"should send the response embedded in the completed progress value", ^{
    FBRHTTPResponse *response =
        [[FBRHTTPResponse alloc] initWithMetadata:OCMClassMock([NSHTTPURLResponse class])
                                          content:nil];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithProgress:0.5]];
    [subject sendNext:[[FBRHTTPTaskProgress alloc] initWithResponse:response]];

    expect(recorder).to.sendValues(@[response]);
    expect(recorder).toNot.complete();
  });

  it(@"should complete when the underlying signal completes", ^{
    [subject sendCompleted];
    expect(recorder).to.complete();
  });

  it(@"should err when the underlying signal errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    [subject sendError:error];

    expect(recorder).to.sendError(error);
  });
});

SpecEnd
