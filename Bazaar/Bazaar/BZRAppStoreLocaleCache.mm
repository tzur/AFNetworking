// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRAppStoreLocaleCache.h"

#import "BZRKeychainStorageRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRAppStoreLocaleCache ()

/// Keychain storage used to store and retrieve App Store locale of multiple applications.
@property (readonly, nonatomic) BZRKeychainStorageRoute *keychainStorageRoute;

@end

/// Key to which the App Store locale is written to.
NSString * const kAppStoreLocaleKey = @"appStoreLocale";

@implementation BZRAppStoreLocaleCache

- (instancetype)initWithKeychainStorageRoute:(BZRKeychainStorageRoute *)keychainStorageRoute {
  if (self = [super init]) {
    _keychainStorageRoute = keychainStorageRoute;
  }
  return self;
}

- (BOOL)storeAppStoreLocale:(nullable NSLocale *)appStoreLocale bundleID:(NSString *)bundleID
                      error:(NSError * __autoreleasing *)error {
  return [self.keychainStorageRoute setValue:appStoreLocale.localeIdentifier
                                      forKey:kAppStoreLocaleKey serviceName:bundleID error:error];
}

- (nullable NSLocale *)appStoreLocaleForBundleID:(NSString *)bundleID
                                           error:(NSError * __autoreleasing *)error {
  auto _Nullable appStoreLocaleIdentifier = (NSString *)[self.keychainStorageRoute
      valueForKey:kAppStoreLocaleKey serviceName:bundleID error:error];

  if (!appStoreLocaleIdentifier || error) {
    return nil;
  }

  return [NSLocale localeWithLocaleIdentifier:appStoreLocaleIdentifier];
}

@end

NS_ASSUME_NONNULL_END
