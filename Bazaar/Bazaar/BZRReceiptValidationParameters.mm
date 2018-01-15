// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParameters

- (instancetype)initWithCurrentApplicationBundleID:(NSString *)currentApplicationBundleID
    applicationBundleID:(NSString *)applicationBundleID receiptData:(nullable NSData *)receiptData
    deviceID:(nullable NSUUID *)deviceID appStoreLocale:(nullable NSLocale *)appStoreLocale
    userID:(nullable NSString *)userID {
  if (self = [super init]) {
    _currentApplicationBundleID = [currentApplicationBundleID copy];
    _applicationBundleID = [applicationBundleID copy];
    _receiptData = receiptData;
    _deviceID = deviceID;
    _appStoreLocale = appStoreLocale;
    _userID = [userID copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
