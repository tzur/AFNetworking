// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptDataCache.h"

#import "BZRKeychainStorageRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptDataCache ()

/// Keychain storage used to store and retrieve receipt data of multiple applications.
@property (readonly, nonatomic) BZRKeychainStorageRoute *keychainStorageRoute;

/// Current application's bundle ID.
@property (readonly, nonatomic) NSString *currentApplicationBundleID;

@end

/// Storage key to which the cached receipt data is written to.
NSString * const kReceiptDataKey = @"receiptData";

@implementation BZRReceiptDataCache

- (instancetype)initWithKeychainStorageRoute:(BZRKeychainStorageRoute *)keychainStorageRoute
                  currentApplicationBundleID:(NSString *)currentApplicationBundleID {
  if (self = [super init]) {
    _keychainStorageRoute = keychainStorageRoute;
    _currentApplicationBundleID = currentApplicationBundleID;
  }
  return self;
}

- (void)storeReceiptData {
  auto _Nullable receiptData =
      [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];

  if (!receiptData) {
    return;
  }

  [self.keychainStorageRoute setValue:receiptData forKey:kReceiptDataKey
                          serviceName:self.currentApplicationBundleID error:nil];
}

- (nullable NSData *)receiptDataForBundleID:(NSString *)bundleID
                                      error:(NSError * __autoreleasing *)error {
  return (NSData *)[self.keychainStorageRoute valueForKey:kReceiptDataKey serviceName:bundleID
                                                    error:error];
}

@end

NS_ASSUME_NONNULL_END
