// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoSource.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake ID used as an identifier for vendor.
extern NSUUID * const kINTFakeIdentifierForVendor;

/// Fake implementation of \c INTDeviceInfoSource for tests.
@interface INTFakeDeviceInfoSource : NSObject <INTDeviceInfoSource>

/// Template used for creating new device info objects.
@property (strong, nonatomic) NSDictionary *deviceInfoTemplate;

@end

NS_ASSUME_NONNULL_END
