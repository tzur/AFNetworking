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
#import "NSError+AFNetworkingAdapter.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRAFNetworkingSessionAdapter

- (instancetype)init {
  return [self initWithBaseURL:nil configuration:[[FBRHTTPSessionConfiguration alloc] init]];
}

- (instancetype)initWithBaseURL:(nullable NSURL *)baseURL
                  configuration:(FBRHTTPSessionConfiguration *)configuration {
  AFHTTPSessionManager *sessionManager =
      [AFHTTPSessionManager fbr_sessionManagerWithBaseURL:baseURL fiberConfiguration:configuration];
  return [self initWithSessionManager:sessionManager];
}

- (instancetype)initWithSessionManager:(AFHTTPSessionManager *)sessionManager {
  if (self = [super init]) {
    _sessionManager = sessionManager;
  }
  return self;
}

- (nullable NSURLSessionDataTask *)dataTaskWithRequest:(FBRHTTPRequest *)request
                                              progress:(nullable FBRHTTPTaskProgressBlock)progress
                                               success:(FBRHTTPTaskSuccessBlock)success
                                               failure:(FBRHTTPTaskFailureBlock)failure {
  LTParameterAssert(success, @"Success callback must be provided, got nil");
  LTParameterAssert(failure, @"Failure callback must be provided, got nil");

  NSError *error;
  NSURLRequest *serializedRequest = [self serializedRequestWithFiberRequest:request error:&error];
  if (error) {
    dispatch_async(self.sessionManager.completionQueue, ^{
      failure(error);
    });
    return nil;
  }

  FBRHTTPTaskProgressBlock uploadProgress = nil;
  FBRHTTPTaskProgressBlock downloadProgress = nil;
  if (request.method.uploadsData) {
    uploadProgress = progress;
  } else if (request.method.downloadsData) {
    downloadProgress = progress;
  }

  // Note: AFNetworking declares the \c responseMetadata argument passed to the completion handler
  // as non-null, however after some research it appears that this argument can actually be \c nil
  // in some scenarios. For example if an error occurred before the request was sent or before the
  // server response was received.
  NSURLSessionDataTask *task =
      [self.sessionManager dataTaskWithRequest:serializedRequest uploadProgress:uploadProgress
                              downloadProgress:downloadProgress
                             completionHandler:^(NSURLResponse * _Nullable responseMetadata,
                                                 id _Nullable responseData,
                                                 NSError * _Nullable error) {
    FBRHTTPResponse *response = responseMetadata ?
        [[FBRHTTPResponse alloc] initWithMetadata:(NSHTTPURLResponse *)responseMetadata
                                          content:(NSData *)responseData] : nil;
    if (error) {
      failure([error fbr_fiberErrorWithRequest:request response:response]);
      return;
    }
    success(response);
  }];

  if (!task) {
    dispatch_async(self.sessionManager.completionQueue, ^{
      failure([NSError fbr_errorWithCode:FBRErrorCodeHTTPTaskInitiationFailed HTTPRequest:request
                         underlyingError:nil]);
    });
  }

  return task;
}

- (nullable NSURLRequest *)serializedRequestWithFiberRequest:(FBRHTTPRequest *)request
                                                       error:(NSError * _Nullable *)error {
  AFHTTPRequestSerializer *serializer =
      [AFHTTPRequestSerializer fbr_serializerForRequest:request
                                  withDefaultSerializer:self.sessionManager.requestSerializer];
  return [serializer fbr_serializedRequestWithRequest:request error:error];
}

@end

NS_ASSUME_NONNULL_END
