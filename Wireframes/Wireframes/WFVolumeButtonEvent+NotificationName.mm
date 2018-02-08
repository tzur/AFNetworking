// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "WFVolumeButtonEvent+NotificationName.h"

#import <LTKit/LTBidirectionalMap.h>

NS_ASSUME_NONNULL_BEGIN

@implementation WFVolumeButtonEvent (NotificationName)

/// Bidirectional map mapping \c WFVolumeButtonEvent to its corresponding \c NSNotificationCenter
/// notification name.
static LTBidirectionalMap<WFVolumeButtonEvent *, NSString *> *map;

static LTBidirectionalMap *WFVolumeButtonEventToNotificationNameMap() {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    map = [LTBidirectionalMap mapWithDictionary:@{
      $(WFVolumeButtonEventVolumeDownPress): @"_UIApplicationVolumeDownButtonDownNotification",
      $(WFVolumeButtonEventVolumeDownRelease): @"_UIApplicationVolumeDownButtonUpNotification",
      $(WFVolumeButtonEventVolumeUpPress): @"_UIApplicationVolumeUpButtonDownNotification",
      $(WFVolumeButtonEventVolumeUpRelease): @"_UIApplicationVolumeUpButtonUpNotification"
    }];
  });
  return map;
}

- (NSString *)notificationName {
  return WFVolumeButtonEventToNotificationNameMap()[self];
}

+ (nullable WFVolumeButtonEvent *)volumeButtonEventFromNotificationName:(NSString *)name {
  return [WFVolumeButtonEventToNotificationNameMap() keyForObject:name];
}

@end

NS_ASSUME_NONNULL_END
