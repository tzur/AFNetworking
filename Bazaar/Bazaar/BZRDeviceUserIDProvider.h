// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRUserIDProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provides a unique identifier of the user for the currently running device.
///
/// @Note A user with multiple devices will have different IDs across devices.
@interface BZRDeviceUserIDProvider : NSObject <BZRUserIDProvider>
@end

NS_ASSUME_NONNULL_END
