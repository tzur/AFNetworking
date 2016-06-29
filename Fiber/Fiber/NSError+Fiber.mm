// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+Fiber.h"

#import <LTKit/NSError+LTKit.h>

#import "FBRHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kFBRFailingHTTPRequestKey = @"FailingRequest";
NSString * const kFBRFailingHTTPResponseKey = @"FailingResponse";

@implementation NSError (Fiber)

+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(FBRHTTPRequest *)request
               underlyingError:(nullable NSError *)underlyingError {
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
  userInfo[kFBRFailingHTTPRequestKey] = [request copy];
  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = underlyingError;
  }
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

+ (NSError *)fbr_errorWithCode:(NSInteger)code HTTPRequest:(FBRHTTPRequest *)request
                  HTTPResponse:(NSHTTPURLResponse *)response
               underlyingError:(nullable NSError *)underlyingError {
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary dictionary];
  userInfo[kFBRFailingHTTPRequestKey] = [request copy];
  userInfo[kFBRFailingHTTPResponseKey] = [response copy];
  if (underlyingError) {
    userInfo[NSUnderlyingErrorKey] = underlyingError;
  }
  return [NSError lt_errorWithCode:code userInfo:userInfo];
}

- (nullable FBRHTTPRequest *)fbr_HTTPRequest {
  return self.userInfo[kFBRFailingHTTPRequestKey];
}

- (nullable NSHTTPURLResponse *)fbr_HTTPResponse {
  return self.userInfo[kFBRFailingHTTPResponseKey];
}

@end

NS_ASSUME_NONNULL_END
