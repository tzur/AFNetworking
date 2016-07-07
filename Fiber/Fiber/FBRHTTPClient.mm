// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPClient.h"

#import "FBRAFNetworkingSessionAdapter.h"
#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"
#import "FBRHTTPSession.h"
#import "FBRHTTPSessionConfiguration.h"
#import "FBRHTTPTaskProgress.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark FBRHTTPRequest+FBRHTTPClient
#pragma mark -

/// Adds convenience methods for \c FBRHTTPClient.
@interface FBRHTTPRequest (FBRHTTPClient)

/// Creates a new HTTP request to a URL composed from \c baseURL and \c URLString with the specified
/// HTTP \c method and optional \c parameters. The reuqest \c parametersEncdoing and \c headers are
/// set to \c nil. If the concatenation of \c URLString to \c baseURL forms an invalid URL an
/// \c NSInvalidArgumentException is raised.
+ (instancetype)requestWithBaseURL:(nullable NSURL *)baseURL URLString:(NSString *)URLString
                            method:(FBRHTTPRequestMethod *)method
                        parameters:(nullable FBRHTTPRequestParameters *)parameters;

/// Returns a URL composed of \c URLString prefixed by \c baseURL. If the resulting URL is invalid
/// an \c NSInvalidArgumentException is raised.
+ (NSURL *)requestURLWithBaseURL:(nullable NSURL *)baseURL URLString:(NSString *)URLString;

@end

@implementation FBRHTTPRequest (FBRHTTPClient)

+ (instancetype)requestWithBaseURL:(nullable NSURL *)baseURL URLString:(NSString *)URLString
                            method:(FBRHTTPRequestMethod *)method
                        parameters:(nullable FBRHTTPRequestParameters *)parameters {
  NSURL *URL = [self requestURLWithBaseURL:baseURL URLString:URLString];
  return [[self alloc] initWithURL:URL method:method parameters:parameters parametersEncoding:nil
                           headers:nil];
}

+ (NSURL *)requestURLWithBaseURL:(nullable NSURL *)baseURL URLString:(NSString *)URLString {
  NSURL *requestURL = baseURL ? [NSURL URLWithString:URLString relativeToURL:baseURL] :
      [NSURL URLWithString:URLString];
  LTParameterAssert(requestURL, @"Invalid combination of base URL and URL string provided, got "
                    "base URL: (%@); URL string: (%@)", baseURL, URLString);
  return requestURL;
}

@end

#pragma mark -
#pragma mark FBRHTTPClient
#pragma mark -

@implementation FBRHTTPClient

+ (instancetype)client {
  return [self clientWithSessionConfiguration:[[FBRHTTPSessionConfiguration alloc] init]
                                      baseURL:nil];
}

+ (instancetype)clientWithSessionConfiguration:(FBRHTTPSessionConfiguration *)configuration
                                       baseURL:(nullable NSURL *)baseURL {
  id<FBRHTTPSession> session =
      [[FBRAFNetworkingSessionAdapter alloc] initWithConfiguration:configuration];
  return [[self alloc] initWithSession:session baseURL:baseURL];
}

- (instancetype)initWithSession:(id<FBRHTTPSession>)session baseURL:(nullable NSURL *)baseURL {
  LTParameterAssert(!baseURL || [FBRHTTPRequest isProtocolSupported:baseURL], @"Base URL must be a "
                    "valid HTTP URL, got %@ with unsupported scheme", baseURL);
  LTParameterAssert(!baseURL.fragment && !baseURL.query, @"Base URL must not specify a fragment or "
                    "query string, got %@", baseURL);

  if (self = [super init]) {
    _session = session;
    _baseURL = baseURL;
  }
  return self;
}

- (RACSignal *)GET:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodGet)
                                                       parameters:parameters]];
}

- (RACSignal *)HEAD:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodHead)
                                                       parameters:parameters]];
}

- (RACSignal *)POST:(NSString *)URLString
     withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodPost)
                                                       parameters:parameters]];
}

- (RACSignal *)PUT:(NSString *)URLString
    withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodPut)
                                                       parameters:parameters]];
}

- (RACSignal *)PATCH:(NSString *)URLString
      withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodPatch)
                                                       parameters:parameters]];
}

- (RACSignal *)DELETE:(NSString *)URLString
       withParameters:(nullable FBRHTTPRequestParameters *)parameters {
  return [self taskWithRequest:[FBRHTTPRequest requestWithBaseURL:self.baseURL URLString:URLString
                                                           method:$(FBRHTTPRequestMethodDelete)
                                                       parameters:parameters]];
}

- (RACSignal *)taskWithRequest:(FBRHTTPRequest *)request {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    NSURLSessionDataTask *task =
        [self.session dataTaskWithRequest:request progress:^(NSProgress *progress) {
          FBRHTTPTaskProgress *taskProgress =
              [[FBRHTTPTaskProgress alloc] initWithProgress:progress.fractionCompleted];
          [subscriber sendNext:taskProgress];
        } success:^(FBRHTTPResponse *response) {
          FBRHTTPTaskProgress *taskProgress =
              [[FBRHTTPTaskProgress alloc] initWithResponse:response];
          [subscriber sendNext:taskProgress];
          [subscriber sendCompleted];
        } failure:^(NSError *error) {
          [subscriber sendError:error];
        }];
    [task resume];
    
    return [RACDisposable disposableWithBlock:^{
      [task cancel];
    }];
  }];
}

@end

NS_ASSUME_NONNULL_END
