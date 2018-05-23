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

- (RACSignal<FBRHTTPResponse *> *)fbr_skipProgress {
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
  return [self tryMap:^id _Nullable(FBRHTTPResponse *response, NSError * __autoreleasing *error) {
    LTAssert([response isKindOfClass:[FBRHTTPResponse class]], @"Expected a signal of "
             "FBRHTTPResponse values, got: %@", [response class]);

    return [response deserializeJSONContentWithError:error];
  }];
}

@end

NS_ASSUME_NONNULL_END
