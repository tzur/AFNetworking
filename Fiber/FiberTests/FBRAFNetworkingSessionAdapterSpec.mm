// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRAFNetworkingSessionAdapter.h"

#import <AFNetworking/AFNetworking.h>

#import "AFNetworking+Fiber.h"
#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"
#import "FBRHTTPSessionConfiguration.h"
#import "FBRHTTPSessionRequestMarshalling.h"
#import "FBRHTTPSessionSecurityPolicy.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

// AFURLSession task callbacks protoypes.
typedef void (^AFURLSessionTaskProgressBlock)(NSProgress *uploadProgress);
typedef void (^AFURLSessionTaskCompletionBlock)(NSURLResponse *response,
                                                id _Nullable responseObject,
                                                NSError * _Nullable error);

// Fake serializer that can fail serialization with a specific error on demand.
@interface FBROnDemandFailingRequestSerializer : AFHTTPRequestSerializer

// Error to report when the serializer is requested to serialize a request.
@property (nonatomic, nullable) NSError *serializationError;

@end

@implementation FBROnDemandFailingRequestSerializer

+ (AFHTTPRequestSerializer *)fbr_serializerForRequest:(FBRHTTPRequest __unused *)request
                                withDefaultSerializer:(AFHTTPRequestSerializer *)defaultSerializer {
  return defaultSerializer;
}

- (nullable NSURLRequest *)fbr_serializedRequestWithRequest:(FBRHTTPRequest *)request
                                                      error:(NSError * _Nullable *)error {
  if (self.serializationError) {
    if (error) {
      *error = self.serializationError;
    }
    return nil;
  }

  return [super fbr_serializedRequestWithRequest:request error:error];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  FBROnDemandFailingRequestSerializer *serializer = [super copyWithZone:zone];
  serializer.serializationError = [self.serializationError copyWithZone:zone];
  return serializer;
}

@end

SpecBegin(FBRAFNetworkingSessionAdapter)

context(@"initialization with configuration", ^{
  __block FBRHTTPSessionConfiguration *configuration;

  beforeEach(^{
    NSSet<NSData *> *certificates =
        [NSSet setWithObject:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]];
    FBRHTTPSessionSecurityPolicy *securityPolicy =
        [FBRHTTPSessionSecurityPolicy securityPolicyWithPinnedCertificates:certificates];
    FBRHTTPSessionRequestMarshalling *requestMarshalling =
        [[FBRHTTPSessionRequestMarshalling alloc] init];
    NSURLSessionConfiguration *sessionConfiguration =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration =
        [[FBRHTTPSessionConfiguration alloc] initWithSessionConfiguration:sessionConfiguration
                                                       requestMarshalling:requestMarshalling
                                                           securityPolicy:securityPolicy];
  });

  it(@"should initialize the session manager with the specified configuration and base URL", ^{
    NSURL *baseURL = [NSURL URLWithString:@"http://foo.bar"];
    id sessionManagerMock = OCMClassMock([AFHTTPSessionManager class]);
    OCMStub([sessionManagerMock fbr_sessionManagerWithBaseURL:baseURL
                                           fiberConfiguration:configuration])
        .andReturn(sessionManagerMock);
    FBRAFNetworkingSessionAdapter *sessionAdapter =
        [[FBRAFNetworkingSessionAdapter alloc] initWithBaseURL:baseURL configuration:configuration];

    expect(sessionAdapter.sessionManager).to.beIdenticalTo(sessionManagerMock);
  });
});

context(@"data tasks", ^{
  __block id sessionManagerMock;
  __block FBROnDemandFailingRequestSerializer *requestSerializer;
  __block dispatch_queue_t completionQueue;
  __block FBRAFNetworkingSessionAdapter *sessionAdapter;
  __block FBRHTTPRequest *request;
  __block NSURLRequest *serializedRequest;

  beforeEach(^{
    sessionManagerMock = OCMClassMock([AFHTTPSessionManager class]);
    requestSerializer = [FBROnDemandFailingRequestSerializer serializer];
    completionQueue = dispatch_get_main_queue();
    OCMStub([sessionManagerMock requestSerializer]).andReturn(requestSerializer);
    OCMStub([sessionManagerMock completionQueue]).andReturn(completionQueue);

    sessionAdapter =
        [[FBRAFNetworkingSessionAdapter alloc] initWithSessionManager:sessionManagerMock];
    request = [[FBRHTTPRequest alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                           method:$(FBRHTTPRequestMethodGet)
                                       parameters:@{@"foo": @"bar"}
                               parametersEncoding:nil headers:@{@"Foo": @"Bar"}];
    serializedRequest = [[AFHTTPRequestSerializer fbr_serializerForRequest:request
                                                     withDefaultSerializer:requestSerializer]
                         fbr_serializedRequestWithRequest:request error:nil];
  });

  context(@"request serialization error", ^{
    __block NSError *serializationError;

    beforeEach(^{
      serializationError = [NSError lt_errorWithCode:1337];
      requestSerializer.serializationError = serializationError;
    });

    it(@"should return nil on request serialization error", ^{
      NSURLSessionTask *task = [sessionAdapter dataTaskWithRequest:request progress:nil
                                                           success:^(FBRHTTPResponse * _Nonnull) {}
                                                           failure:^(NSError * _Nonnull) {}];
      expect(task).to.beNil();
    });

    it(@"should provide an error to the failure block on request serialization error", ^{
      __block NSError *reportedError;
      [sessionAdapter dataTaskWithRequest:request progress:nil
                                  success:^(FBRHTTPResponse * _Nonnull) {}
                                  failure:^(NSError * _Nonnull error) {
                                    reportedError = error;
                                  }];

      expect(reportedError).will.equal(serializationError);
    });
  });

  context(@"request forwarding", ^{
    __block id task;
    __block NSHTTPURLResponse *responseMetadata;
    __block NSData *responseData;
    __block FBRHTTPResponse *response;

    beforeEach(^{
      task = OCMClassMock([NSURLSessionDataTask class]);
      responseData = [@"Foo" dataUsingEncoding:NSUTF8StringEncoding];
      responseMetadata = [[NSHTTPURLResponse alloc] initWithURL:request.URL MIMEType:nil
                                          expectedContentLength:responseData.length
                                               textEncodingName:nil];
      response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata content:responseData];
    });

    it(@"should initiate a task on the session manager with the serialized request", ^{
      OCMExpect([sessionManagerMock dataTaskWithRequest:serializedRequest uploadProgress:OCMOCK_ANY
                                       downloadProgress:OCMOCK_ANY
                                      completionHandler:[OCMArg isNotNil]]).andReturn(task);
      [sessionAdapter dataTaskWithRequest:request progress:nil success:^(FBRHTTPResponse *) {}
                                  failure:^(NSError *) {}];

      OCMVerifyAll(sessionManagerMock);
    });

    it(@"should provide the correct progress block according to request method", ^{
      NSURL *URL = request.URL;
      [FBRHTTPRequestMethod enumerateEnumUsingBlock:^(FBRHTTPRequestMethod *value) {
        FBRHTTPRequest *request = [[FBRHTTPRequest alloc] initWithURL:URL method:value];
        serializedRequest = [requestSerializer fbr_serializedRequestWithRequest:request error:nil];
        id expectedUploadProgress = value.uploadsData ? [OCMArg isNotNil] : [OCMArg isNil];
        id expectedDownloadProgress = value.downloadsData ? [OCMArg isNotNil] : [OCMArg isNil];

        OCMExpect([sessionManagerMock dataTaskWithRequest:serializedRequest
                                           uploadProgress:expectedUploadProgress
                                         downloadProgress:expectedDownloadProgress
                                        completionHandler:[OCMArg isNotNil]]).andReturn(task);
        [sessionAdapter dataTaskWithRequest:request progress:^(NSProgress *) {}
                                    success:^(FBRHTTPResponse *) {} failure:^(NSError *) {}];
      }];

      OCMVerifyAll(sessionManagerMock);
    });

    it(@"should invoke failure block if task initiation failed", ^{
      OCMStub([sessionManagerMock dataTaskWithRequest:serializedRequest uploadProgress:OCMOCK_ANY
                                     downloadProgress:OCMOCK_ANY
                                    completionHandler:[OCMArg isNotNil]]);
      __block NSError *reportedError;
      [sessionAdapter dataTaskWithRequest:request progress:nil success:^(FBRHTTPResponse *) {}
                                  failure:^(NSError *error) {
                                    reportedError = error;
                                  }];

      expect(reportedError.domain).will.equal(kLTErrorDomain);
      expect(reportedError.code).will.equal(FBRErrorCodeHTTPTaskInitiationFailed);
      expect(reportedError.fbr_HTTPRequest).will.equal(request);
    });

    it(@"should invoke the failure block if task completion block invoked with error", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      id completion = [OCMArg invokeBlockWithArgs:responseMetadata, responseData, error, nil];
      OCMStub([sessionManagerMock dataTaskWithRequest:serializedRequest uploadProgress:OCMOCK_ANY
                                     downloadProgress:OCMOCK_ANY completionHandler:completion])
          .andReturn(task);

      __block NSError *reportedError;
      [sessionAdapter dataTaskWithRequest:request progress:nil success:^(FBRHTTPResponse *) {}
                                  failure:^(NSError *error) {
                                    reportedError = error;
                                  }];

      expect(reportedError.domain).will.equal(kLTErrorDomain);
      expect(reportedError.code).will.equal(FBRErrorCodeHTTPTaskFailed);
      expect(reportedError.fbr_HTTPRequest).will.beNil();
      expect(reportedError.fbr_HTTPResponse).will.equal(response);
      expect(reportedError.lt_underlyingError).will.equal(error);
    });

    it(@"should invoke success block if task completion block invoked with no error", ^{
      id completion = [OCMArg invokeBlockWithArgs:responseMetadata, responseData, [NSNull null],
                       nil];
      OCMStub([sessionManagerMock dataTaskWithRequest:serializedRequest uploadProgress:OCMOCK_ANY
                                     downloadProgress:OCMOCK_ANY completionHandler:completion])
          .andReturn(task);

      __block FBRHTTPResponse *reportedResponse;
      [sessionAdapter dataTaskWithRequest:request progress:nil
                                  success:^(FBRHTTPResponse *response) {
                                    reportedResponse = response;
                                  } failure:^(NSError *) {}];

      expect(reportedResponse).will.equal(response);
    });

    it(@"should invoke progress block on task progress", ^{
      NSProgress *taskProgress = [NSProgress progressWithTotalUnitCount:100];
      taskProgress.completedUnitCount = 50;
      id downloadProgress = [OCMArg invokeBlockWithArgs:taskProgress, nil];
      OCMStub([sessionManagerMock dataTaskWithRequest:serializedRequest uploadProgress:OCMOCK_ANY
                                     downloadProgress:downloadProgress
                                    completionHandler:[OCMArg isNotNil]]).andReturn(task);

      __block NSProgress *reportedProgress;
      [sessionAdapter dataTaskWithRequest:request progress:^(NSProgress *progress) {
        reportedProgress = progress;
      } success:^(FBRHTTPResponse *) {} failure:^(NSError *) {}];

      expect(reportedProgress).will.equal(taskProgress);
    });
  });
});

SpecEnd
