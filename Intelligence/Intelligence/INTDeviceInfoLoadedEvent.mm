// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTDeviceInfoLoadedEvent.h"

NS_ASSUME_NONNULL_BEGIN

@implementation INTDeviceInfoLoadedEvent

- (instancetype)initWithDeviceInfo:(INTDeviceInfo *)deviceInfo
              deviceInfoRevisionID:(NSUUID *)deviceInfoRevisionID
                     isNewRevision:(BOOL)isNewRevision {
  if (self = [super init]) {
    _deviceInfo = deviceInfo;
    _deviceInfoRevisionID = deviceInfoRevisionID;
    _isNewRevision = isNewRevision;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
