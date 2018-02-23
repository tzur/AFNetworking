// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "NSError+AFNetworkingAdapter.h"

#import <AFNetworking/AFNetworking.h>

#import "FBRHTTPRequest.h"
#import "FBRHTTPResponse.h"
#import "NSError+Fiber.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSError (AFNetworkingAdapter)

- (NSError *)fbr_fiberErrorWithRequest:(nullable FBRHTTPRequest *)request
                              response:(nullable FBRHTTPResponse *)response {
  NSInteger fiberErrorCode = FBRErrorCodeHTTPTaskFailed;
  if ([self.domain isEqualToString:AFURLResponseSerializationErrorDomain]) {
    if (self.code == NSURLErrorBadServerResponse) {
      fiberErrorCode = FBRErrorCodeHTTPUnsuccessfulResponseReceived;
    } else if (self.code == NSURLErrorCannotDecodeContentData) {
      fiberErrorCode = FBRErrorCodeHTTPResponseDeserializationFailed;
    }
  } else if (self.code == NSURLErrorCancelled) {
    fiberErrorCode = FBRErrorCodeHTTPTaskCancelled;
  }

  return [NSError fbr_errorWithCode:fiberErrorCode HTTPRequest:request HTTPResponse:response
                    underlyingError:self];
}

@end

NS_ASSUME_NONNULL_END
