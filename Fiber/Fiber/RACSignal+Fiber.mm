// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+Fiber.h"

#import "FBRHTTPResponse.h"
#import "FBRHTTPTaskProgress.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Fiber)

- (RACSignal *)fbr_deserializeJSON {
  return [[self fbr_skipProgress] fbr_deserializeJSONResponse];
}

- (RACSignal *)fbr_skipProgress {
  return [[self
      filter:^BOOL(FBRHTTPTaskProgress *progress) {
        LTAssert([progress isKindOfClass:[FBRHTTPTaskProgress class]], @"Expected a signal of "
                 "FBRHTTPTaskProgress values, got: %@", [progress class]);

        return progress.hasCompleted;
      }]
      map:^FBRHTTPResponse *(FBRHTTPTaskProgress *progress) {
        return progress.response;
      }];
}

- (RACSignal *)fbr_deserializeJSONResponse {
  return [self tryMap:^id _Nullable(FBRHTTPResponse *response, NSError **error) {
    NSData *data = response.content;
    if (!data) {
      if (error) {
        *error = [NSError lt_errorWithCode:FBRErrorCodeJSONDeserializationFailed
                               description:@"Can not deserialize JSON object from nil value"];
      }
      return nil;
    }
    
    NSError *underlyingError;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&underlyingError];
    if (!object || underlyingError) {
      *error = [NSError lt_errorWithCode:FBRErrorCodeJSONDeserializationFailed
                         underlyingError:underlyingError];
      return nil;
    }
    return object;
  }];
}

@end

NS_ASSUME_NONNULL_END
