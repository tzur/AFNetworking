// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

#import "WFVolumeButtonEvents.h"

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c WFVolumeButtonEvent by adding functionality to obtain
/// \c NSNotificationCenter's notifications names for volume button events and vice verse.
@interface WFVolumeButtonEvent (NotificationName)

/// Returns the corresponding notification name, used by \c NSNotificationCenter, for this instance.
- (NSString *)notificationName;

/// Returns the corresponding \c WFVolumeButtonEvent for the given \c name. Returns \c nil if
/// \c name doesn't match any recognized event.
+ (nullable WFVolumeButtonEvent *)volumeButtonEventFromNotificationName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
