// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZRAppStoreLocaleCache.h"
#import "BZRReceiptDataCache.h"
#import "BZRReceiptValidationParameters.h"
#import "NSErrorCodes+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptValidationParametersProvider ()

/// Cache used to store and retrieve App Store locale of multiple applications.
@property (readonly, nonatomic) BZRAppStoreLocaleCache *appStoreLocaleCache;

/// Cache used to store and retrieve receipt data of multiple applications.
@property (readonly, nonatomic) BZRReceiptDataCache *receiptDataCache;

/// Bundle ID of the current application.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

@end

@implementation BZRReceiptValidationParametersProvider

@synthesize appStoreLocale = _appStoreLocale;

- (instancetype)initWithAppStoreLocaleCache:(BZRAppStoreLocaleCache *)appStoreLocaleCache
                           receiptDataCache:(BZRReceiptDataCache *)receiptDataCache
                 currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  if (self = [super init]) {
    _appStoreLocaleCache = appStoreLocaleCache;
    _receiptDataCache = receiptDataCache;
    _currentApplicationBundleID = [currentApplicationBundleID copy];

    [self loadAppStoreLocaleFromStorage];
  }

  return self;
}

- (void)loadAppStoreLocaleFromStorage {
  NSLocale * _Nullable appStoreLocale =
      [self.appStoreLocaleCache appStoreLocaleForBundleID:self.currentApplicationBundleID
                                                    error:nil];

  if (appStoreLocale) {
      _appStoreLocale = appStoreLocale;
  }
}

- (nullable BZRReceiptValidationParameters *)receiptValidationParametersForApplication:
    (NSString *)applicationBundleID {
  NSUUID * _Nullable deviceID = [[UIDevice currentDevice] identifierForVendor];
  NSData * _Nullable receiptData;
  NSLocale * _Nullable appStoreLocale;

  if ([applicationBundleID isEqualToString:self.currentApplicationBundleID]) {
    receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    appStoreLocale = self.appStoreLocale;
  } else {
    receiptData = [self.receiptDataCache receiptDataForApplicationBundleID:applicationBundleID
                                                                     error:nil];
    appStoreLocale = [self.appStoreLocaleCache appStoreLocaleForBundleID:applicationBundleID
                                                                   error:nil];
  }

  if (!receiptData) {
    return nil;
  }

  return [[BZRReceiptValidationParameters alloc]
          initWithCurrentApplicationBundleID:self.currentApplicationBundleID
          applicationBundleID:applicationBundleID receiptData:receiptData deviceID:deviceID
          appStoreLocale:appStoreLocale userID:nil];
}

- (nullable NSLocale *)appStoreLocale {
  @synchronized(self) {
    return _appStoreLocale;
  }
}

- (void)setAppStoreLocale:(nullable NSLocale *)appStoreLocale {
  @synchronized(self) {
    if (appStoreLocale == _appStoreLocale || [appStoreLocale isEqual:_appStoreLocale]) {
      return;
    }

    _appStoreLocale = appStoreLocale;
    [self storeAppStoreLocaleToStorage:appStoreLocale];
  }
}

- (void)storeAppStoreLocaleToStorage:(nullable NSLocale *)appStoreLocale {
  [self.appStoreLocaleCache storeAppStoreLocale:appStoreLocale
                                       bundleID:self.currentApplicationBundleID
                                          error:nil];
}

@end

NS_ASSUME_NONNULL_END
