// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>

#import "INTAnalytricksEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface INTAloomaLogger ()

/// Used to record events into the Alooma service.
@property (readonly, nonatomic) Alooma *aloomaRecorder;

@end

@implementation INTAloomaLogger

/// Default server URL of the Alooma service.
static NSString * const kAloomaServerURL = @"https://inputs.alooma.com";

- (instancetype)initWithAPIToken:(NSString *)apiToken flushInterval:(NSUInteger)flushInterval
                     application:(nullable UIApplication *)application {
  auto aloomaRecorder = [[Alooma alloc] initWithToken:apiToken serverURL:kAloomaServerURL
                                     andFlushInterval:flushInterval application:application];
  return [self initWithAlooma:aloomaRecorder];
}

- (instancetype)initWithAlooma:(Alooma *)aloomaRecorder {
  if (self = [super init]) {
    _aloomaRecorder = aloomaRecorder;
  }
  return self;
}

- (void)logEvent:(id<INTAnalytricksEvent>)event {
  if (![self isEventSupported:event]) {
    return;
  }

  [self.aloomaRecorder trackCustomEvent:event.properties];
}

- (BOOL)isEventSupported:(id)event {
  return [event conformsToProtocol:@protocol(INTAnalytricksEvent)];
}

@end

NS_ASSUME_NONNULL_END
