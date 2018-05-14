// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTAloomaLogger.h"

#import <Alooma-iOS/Alooma.h>
#import <LTKit/NSArray+NSSet.h>

#import "INTAnalytricksDeepLinkOpened.h"
#import "INTAnalytricksDeviceInfoChanged.h"
#import "INTAnalytricksDeviceTokenChanged.h"
#import "INTAnalytricksPushNotificationOpened.h"
#import "INTAnalytricksSubscriptionInfoChanged.h"
#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

NSSet<NSString *> * const kINTDefaultWhitelistedEvents = [@[
  kINTAnalytricksDeepLinkOpenedName,
  kINTAnalytricksDeviceInfoChangedName,
  kINTAnalytricksDeviceTokenChangedName,
  kINTAnalytricksPushNotificationOpenedName,
  kINTAnalytricksSubscriptionInfoChangedName
] lt_set];

NSDictionary *INTAloomaJSONSerializationErrorEvent(NSDictionary *event, UIDevice *device) {
  auto identifierForVendor = [device identifierForVendor] ?: [NSUUID int_zeroUUID];
  return  @{
    @"event": @"alooma_json_serialization_error",
    @"event_description": [event description],
    @"original_event_type": event[@"event"],
    @"id_for_vendor": identifierForVendor.UUIDString
  };
}

@interface INTAloomaLogger ()

/// Used to record events into the Alooma service.
@property (readonly, nonatomic) Alooma *aloomaRecorder;

/// Events that are supported if \c shouldWhitelistEvents is \c YES.
@property (readonly, nonatomic) NSSet<NSString *> *whitelistedEvents;

@end

@implementation INTAloomaLogger

/// Default server URL of the Alooma service.
static NSString * const kAloomaServerURL = @"https://inputs.alooma.com";

- (instancetype)initWithAPIToken:(NSString *)apiToken flushInterval:(NSUInteger)flushInterval
                     application:(nullable UIApplication *)application
               whitelistedEvents:(NSSet<NSString *> *)whitelistedEvents {
  auto aloomaRecorder = [[Alooma alloc] initWithToken:apiToken serverURL:kAloomaServerURL
                                     andFlushInterval:flushInterval application:application];
  return [self initWithAlooma:aloomaRecorder whitelistedEvents:whitelistedEvents];
}

- (instancetype)initWithAlooma:(Alooma *)aloomaRecorder
             whitelistedEvents:(NSSet<NSString *> *)whitelistedEvents {
  if (self = [super init]) {
    _aloomaRecorder = aloomaRecorder;
    _whitelistedEvents = whitelistedEvents;
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
  if ([event isKindOfClass:NSDictionary.class] && [event[@"event"] isKindOfClass:NSString.class]) {
    return !(self.shouldWhitelistEvents &&
             ![self.whitelistedEvents containsObject:event[@"event"]]);
  }

  return NO;
}

@end

NS_ASSUME_NONNULL_END
