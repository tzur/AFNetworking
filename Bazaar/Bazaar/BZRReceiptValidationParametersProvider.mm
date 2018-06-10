// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRAppStoreLocaleProvider.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationParametersProvider ()

/// Provider used to provide App Store locale of multiple applications.
@property (readonly, nonatomic) BZRAppStoreLocaleProvider *appStoreLocaleProvider;

/// Cache used to store and retrieve receipt data of multiple applications.
@property (readonly, nonatomic) BZRReceiptDataCache *receiptDataCache;

/// Bundle ID of the current application.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

@end

@implementation BZRReceiptValidationParametersProvider

- (instancetype)initWithAppStoreLocaleProvider:(BZRAppStoreLocaleProvider *)appStoreLocaleProvider
                              receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
                    currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  if (self = [super init]) {
    _appStoreLocaleProvider = appStoreLocaleProvider;
    _receiptDataCache = receiptDataCache;
    _currentApplicationBundleID = [currentApplicationBundleID copy];
  }

  return self;
}

- (nullable BZRReceiptValidationParameters *)receiptValidationParametersForApplication:
    (NSString *)applicationBundleID userID:(nullable NSString *)userID {
  NSUUID * _Nullable deviceID = [[UIDevice currentDevice] identifierForVendor];
  NSData * _Nullable receiptData;
  NSLocale * _Nullable appStoreLocale;

  if ([applicationBundleID isEqualToString:self.currentApplicationBundleID]) {
    receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    appStoreLocale = self.appStoreLocaleProvider.appStoreLocale;
  } else {
    receiptData = [self.receiptDataCache receiptDataForApplicationBundleID:applicationBundleID
                                                                     error:nil];
    appStoreLocale = [self.appStoreLocaleProvider appStoreLocaleForBundleID:applicationBundleID
                                                                      error:nil];
  }

  if (!receiptData && !userID) {
    return nil;
  }

  return [[BZRReceiptValidationParameters alloc]
          initWithCurrentApplicationBundleID:self.currentApplicationBundleID
          applicationBundleID:applicationBundleID receiptData:receiptData deviceID:deviceID
          appStoreLocale:appStoreLocale userID:userID];
}

@end

NS_ASSUME_NONNULL_END
