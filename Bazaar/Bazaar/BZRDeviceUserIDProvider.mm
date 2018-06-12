// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRDeviceUserIDProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRDeviceUserIDProvider

- (nullable NSString *)userID {
  return [UIDevice currentDevice].identifierForVendor.UUIDString;
}

@end

NS_ASSUME_NONNULL_END
