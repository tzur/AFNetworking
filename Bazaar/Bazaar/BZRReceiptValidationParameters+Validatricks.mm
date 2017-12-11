// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidationParameters+Validatricks.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRReceiptValidationParameters (Validatricks)

- (NSDictionary<NSString *, NSString *> *)validatricksRequestParameters {
  static NSString * const kRequestingApplicationIDKey = @"originBundle";
  static NSString * const kDeviceIDKey = @"idForVendor";
  static NSString * const kBundleIDKey = @"bundle";
  static NSString * const kReceiptKey = @"receipt";
  static NSString * const kAppStoreCountryCodeKey = @"appStoreCountryCode";
  static NSString * const kUserIDKey = @"userID";

  NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];

  requestParameters[kRequestingApplicationIDKey] = self.currentApplicationBundleID;
  requestParameters[kReceiptKey] =
      [self.receiptData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
  requestParameters[kBundleIDKey] = self.applicationBundleID;

  if (self.deviceID) {
    requestParameters[kDeviceIDKey] = self.deviceID.UUIDString;
  }

  if (self.appStoreLocale) {
    requestParameters[kAppStoreCountryCodeKey] =
        [self.appStoreLocale objectForKey:NSLocaleCountryCode];
  }

  if (self.userID) {
    requestParameters[kUserIDKey] = self.userID;
  }

  return requestParameters;
}

@end

NS_ASSUME_NONNULL_END
