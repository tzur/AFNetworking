// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters+Validatricks.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParameters (Validatricks)

- (NSDictionary<NSString *, NSString *> *)validatricksRequestParameters {
  static NSString * const kApplicationBundleIDKey = @"bundle";
  static NSString * const kDeviceIDKey = @"idForVendor";
  static NSString * const kReceiptKey = @"receipt";

  NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];

  requestParameters[kApplicationBundleIDKey] = self.applicationBundleId,
  requestParameters[kReceiptKey] =
      [self.receiptData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
  if (self.deviceId) {
    requestParameters[kDeviceIDKey] = self.deviceId.UUIDString;
  }

  return requestParameters;
}

@end

NS_ASSUME_NONNULL_END
