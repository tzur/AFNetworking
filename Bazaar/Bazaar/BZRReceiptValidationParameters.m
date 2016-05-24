// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParameters

+ (nullable instancetype)defaultParameters {
  NSString *applicationBundleId = [[NSBundle mainBundle] bundleIdentifier];
  NSUUID *deviceId = [[UIDevice currentDevice] identifierForVendor];
  NSData *receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
  if (!receiptData) {
    return nil;
  }

  return [[self alloc] initWithReceiptData:receiptData applicationBundleId:applicationBundleId
                                  deviceId:deviceId];
}

- (instancetype)initWithReceiptData:(NSData *)receiptData
                applicationBundleId:(NSString *)applicationBundleId
                           deviceId:(nullable NSUUID *)deviceId {
  LTParameterAssert(receiptData);
  LTParameterAssert(applicationBundleId);

  if (self = [super init]) {
    _receiptData = receiptData;
    _applicationBundleId = applicationBundleId;
    _deviceId = deviceId;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
