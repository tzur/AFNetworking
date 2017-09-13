// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "NSBundleResourceRequest+NoThrow.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSBundleResourceRequest (NoThrow)

static const char *kFBRRequestCompletionQueueLabel = "com.lightricks.fiber.odr";

- (void)fbr_beginAccessingResourcesWithCompletionHandler:
    (void (^)(NSError * _Nullable error))completionHandler {
  @try {
    [self beginAccessingResourcesWithCompletionHandler:completionHandler];
  } @catch (NSException *exception) {
    dispatch_async(dispatch_queue_create(kFBRRequestCompletionQueueLabel, DISPATCH_QUEUE_SERIAL), ^{
      completionHandler([NSError lt_errorWithException:exception]);
    });
  }
}

- (void)fbr_conditionallyBeginAccessingResourcesWithCompletionHandler:
    (void (^)(BOOL resourcesAvailable))completionHandler {
  @try {
    [self conditionallyBeginAccessingResourcesWithCompletionHandler:completionHandler];
  } @catch (NSException *exception) {
    LogError(@"On Demand Resources conditionally begin access has failed with exception: %@",
             exception);
    dispatch_async(dispatch_queue_create(kFBRRequestCompletionQueueLabel, DISPATCH_QUEUE_SERIAL), ^{
      completionHandler(NO);
    });
  }
}

@end

NS_ASSUME_NONNULL_END
