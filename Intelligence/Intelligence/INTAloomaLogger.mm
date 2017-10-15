// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>

#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

NSDictionary *INTAloomaJSONSerializationErrorEvent(NSDictionary *event) {
  return  @{
    @"event": @"alooma_json_serialization_error",
    @"event_description": [event description],
    @"original_event_type": event[@"event"],
    @"id_for_vendor": [[UIDevice currentDevice] identifierForVendor].UUIDString ?:
        [NSUUID int_zeroUUID]
  };
}

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

- (void)logEvent:(NSDictionary *)event {
  if (![self isEventSupported:event]) {
    return;
  }

  if (![NSJSONSerialization isValidJSONObject:event]) {
    [self.aloomaRecorder trackCustomEvent:INTAloomaJSONSerializationErrorEvent(event)];
    return;
  }

  [self.aloomaRecorder trackCustomEvent:event];
}

- (BOOL)isEventSupported:(NSDictionary *)event {
  return [event isKindOfClass:NSDictionary.class] && [event[@"event"] isKindOfClass:NSString.class];
}

@end

NS_ASSUME_NONNULL_END
