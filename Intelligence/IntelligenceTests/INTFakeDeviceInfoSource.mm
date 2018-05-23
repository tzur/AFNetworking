// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTFakeDeviceInfoSource.h"

#import <LTKit/LTKeyPathCoding.h>

#import "INTDeviceInfo.h"
#import "NSDictionary+Merge.h"
#import "NSUUID+Zero.h"

NS_ASSUME_NONNULL_BEGIN

NSUUID * const kINTFakeIdentifierForVendor =
    [[NSUUID alloc] initWithUUIDString:@"123e4567-e89b-12d3-a456-426655440000"];

@implementation INTFakeDeviceInfoSource

- (INTDeviceInfo *)deviceInfoWithAppStoreCountry:(nullable NSString *)appStoreCountry
                             usageEventsDisabled:(nullable NSNumber *)usageEventsDisabled {
  auto dictionary = [self.deviceInfoTemplate int_mergeUpdates:@{
    @instanceKeypath(INTDeviceInfo, appStoreCountry): appStoreCountry ?: [NSNull null],
    @instanceKeypath(INTDeviceInfo, usageEventsDisabled): usageEventsDisabled ?: [NSNull null]
  }];

  return [[INTDeviceInfo alloc] initWithDictionary:dictionary error:nil];
}

@end

NS_ASSUME_NONNULL_END
