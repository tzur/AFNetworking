// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "AFNetworking+Fiber.h"

#import "FBRHTTPSessionConfiguration.h"
#import "FBRHTTPSessionRequestMarshalling.h"
#import "FBRHTTPSessionSecurityPolicy.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark AFSecurityPolicy+Fiber
#pragma mark -

@implementation AFSecurityPolicy (Fiber)

+ (instancetype)fbr_securityPolicyWithFiberSecurityPolicy:
    (FBRHTTPSessionSecurityPolicy *)fiberSecurityPolicy {
  AFSSLPinningMode pinningMode =
      [self fbr_SSLPinningModeWithCertificateValidationMode:fiberSecurityPolicy.validationMode];
  AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:pinningMode];
  securityPolicy.pinnedCertificates = fiberSecurityPolicy.pinnedCertificates;
  return securityPolicy;
}

+ (AFSSLPinningMode)fbr_SSLPinningModeWithCertificateValidationMode:
    (FBRCertificateValidationMode)validationMode {
  switch (validationMode) {
    case FBRCertificateValidationModeStandard:
      return AFSSLPinningModeNone;
    case FBRCertificateValidationModePinnedCertificates:
      return AFSSLPinningModeCertificate;
    case FBRCertificateValidationModePinnedPublicKeys:
      return AFSSLPinningModePublicKey;
    default:
      LTAssert(NO, @"Invalid certificate validation mode specified (%lu)",
               (unsigned long)validationMode);
  }
}

@end

#pragma mark -
#pragma mark AFHTTPRequestSerializer+Fiber
#pragma mark -

@implementation AFHTTPRequestSerializer (Fiber)

+ (instancetype)fbr_serializerWithFiberRequestMarshalling:
  (FBRHTTPSessionRequestMarshalling *)requestMarhsalling {
  AFHTTPRequestSerializer *serializer =
      [self fbr_requestSerializerForParametersEncoding:requestMarhsalling.parametersEncoding];
  if (requestMarhsalling.headers) {
    [serializer fbr_appendHeaders:requestMarhsalling.headers];
  }
  return serializer;
}

+ (AFHTTPRequestSerializer *)fbr_requestSerializerForParametersEncoding:
    (FBRHTTPRequestParametersEncoding *)parametersEncoding {
  switch(parametersEncoding.value) {
    case FBRHTTPRequestParametersEncodingURLQuery:
      return [AFHTTPRequestSerializer serializer];
    case FBRHTTPRequestParametersEncodingJSON:
      return [AFJSONRequestSerializer serializer];
    default:
      LTAssert(NO, @"Invalid parameters encoding specified (%lu)",
               (unsigned long)parametersEncoding);
  }
}

+ (AFHTTPRequestSerializer *)fbr_serializerForRequest:(FBRHTTPRequest *)request
                                withDefaultSerializer:(AFHTTPRequestSerializer *)defaultSerializer {
  AFHTTPRequestSerializer *serializer;
  if (request.parameters && request.parametersEncoding) {
    serializer = [AFHTTPRequestSerializer
                  fbr_requestSerializerForParametersEncoding:request.parametersEncoding];
  } else {
    serializer = [defaultSerializer copy];
  }

  if (request.headers) {
    [serializer fbr_appendHeaders:request.headers];
  }

  return serializer;
}

- (void)fbr_appendHeaders:(FBRHTTPRequestHeaders *)headers {
  // Appends the given \c headers to this serializer's HTTP headers, overwriting serializer's header
  // values with header values from \c headers.
  [headers enumerateKeysAndObjectsUsingBlock:^(NSString * key, NSString * value, BOOL *) {
     [self setValue:value forHTTPHeaderField:key];
   }];
}

- (nullable NSURLRequest *)fbr_serializedRequestWithRequest:(FBRHTTPRequest *)request
                                                      error:(NSError * _Nullable *)error {
  NSError *serializationError;
  NSURLRequest *serializedRequest = [self requestWithMethod:request.method.HTTPMethod
                                                  URLString:request.URL.absoluteString
                                                 parameters:request.parameters
                                                      error:&serializationError];
  if (serializationError) {
    if (error) {
      *error = [NSError fbr_errorWithCode:FBRErrorCodeHTTPRequestSerializationFailed
                              HTTPRequest:request underlyingError:serializationError];
    }
    return nil;
  }

  return serializedRequest;
}

@end

#pragma mark -
#pragma mark AFHTTPSessionManager+Fiber
#pragma mark -

@implementation AFHTTPSessionManager (Fiber)

+ (instancetype)fbr_sessionManagerWithBaseURL:(nullable NSURL *)baseURL
                           fiberConfiguration:(FBRHTTPSessionConfiguration *)configuration {
  LTAssert(configuration.securityPolicy.validationMode == FBRCertificateValidationModeStandard ||
           [baseURL.scheme.lowercaseString isEqualToString:@"https"],
           @"Session SSL pinning is requested but base URL is not an HTTPS URL (%@)", baseURL);

  AFHTTPSessionManager *sessionManager =
      [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL
                               sessionConfiguration:configuration.sessionConfiguration];
  sessionManager.securityPolicy =
      [AFSecurityPolicy fbr_securityPolicyWithFiberSecurityPolicy:configuration.securityPolicy];
  sessionManager.requestSerializer =
      [AFHTTPRequestSerializer fbr_serializerWithFiberRequestMarshalling:
       configuration.requestMarshalling];
  sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
  sessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

  return sessionManager;
}

@end

NS_ASSUME_NONNULL_END
