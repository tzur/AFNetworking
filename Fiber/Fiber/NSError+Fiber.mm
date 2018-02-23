// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Fiber.h"

#import <LTKit/NSError+LTKit.h>

#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kFBRFailingHTTPRequestKey = @"FailingRequest";
NSString * const kFBRFailingHTTPResponseKey = @"FailingResponse";

@implementation NSError (Fiber)

+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(FBRHTTPRequest *)request
               underlyingError:(nullable NSError *)underlyingError {
  return [self fbr_errorWithCode:code HTTPRequest:request HTTPResponse:nil
                 underlyingError:underlyingError];
}

+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(nullable FBRHTTPRequest *)request
                  HTTPResponse:(nullable FBRHTTPResponse *)response
               underlyingError:(nullable NSError *)underlyingError {
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];

  if (request) {
    userInfo[kFBRFailingHTTPRequestKey] = [request copy];
  }

  if (response) {
    userInfo[kFBRFailingHTTPResponseKey] = [response copy];
  }

  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = underlyingError;
  }

  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

- (nullable FBRHTTPRequest *)fbr_HTTPRequest {
  return self.userInfo[kFBRFailingHTTPRequestKey];
}

- (nullable FBRHTTPResponse *)fbr_HTTPResponse {
  return self.userInfo[kFBRFailingHTTPResponseKey];
}

@end

NS_ASSUME_NONNULL_END
