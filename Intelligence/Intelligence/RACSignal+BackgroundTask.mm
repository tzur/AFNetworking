// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "RACSignal+BackgroundTask.h"

#import "NSErrorCodes+Intelligence.h"

NS_ASSUME_NONNULL_BEGIN

@implementation RACSignal (Intelligence)

+ (RACSignal *)backgroundTaskWithSignalBlock:(RACSignal *(^)(void))signalBlock
                                 application:(UIApplication *)application {
  return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
    auto taskDisposable = [RACCompoundDisposable compoundDisposable];
    __block UIBackgroundTaskIdentifier taskIdentifier =
        [application beginBackgroundTaskWithExpirationHandler:^{
          [taskDisposable dispose];
          [application endBackgroundTask:taskIdentifier];
          taskIdentifier = UIBackgroundTaskInvalid;
        }];

    if (taskIdentifier == UIBackgroundTaskInvalid) {
      NSError *error = [NSError lt_errorWithCode:INTErrorCodeBackgroundTaskFailedToStart];
      [subscriber sendError:error];
      return taskDisposable;
    }

    auto disposable = [[[RACSignal
        defer:signalBlock]
        finally:^{
          [application endBackgroundTask:taskIdentifier];
        }]
        subscribe:subscriber];

    [taskDisposable addDisposable:disposable];

    return taskDisposable;
  }];
}

+ (RACSignal *)backgroundTaskWithSignalBlock:(RACSignal * _Nonnull (^)())signalBlock {
  return [self backgroundTaskWithSignalBlock:signalBlock
                                 application:[UIApplication sharedApplication]];
}

@end

NS_ASSUME_NONNULL_END
