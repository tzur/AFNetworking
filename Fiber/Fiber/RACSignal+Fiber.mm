// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "RACSignal+Fiber.h"

#import <LTKit/LTProgress.h>

#import "FBRHTTPResponse.h"
#import "NSErrorCodes+Fiber.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Fiber)

- (RACSignal *)fbr_deserializeJSON {
  return [[self fbr_skipProgress] fbr_deserializeJSONResponse];
}

- (RACSignal *)fbr_skipProgress {
  return [[self
      filter:^BOOL(LTProgress<FBRHTTPResponse *> *progress) {
        LTAssert([progress isKindOfClass:[LTProgress class]], @"Expected a signal of LTProgress"
                 "values, got: %@", [progress class]);

        return progress.result != nil;
      }]
      map:^FBRHTTPResponse *(LTProgress<FBRHTTPResponse *> *progress) {
        return progress.result;
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
