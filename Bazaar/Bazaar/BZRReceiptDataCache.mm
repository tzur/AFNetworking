// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptDataCache.h"

#import "BZRKeychainStorageRoute.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRReceiptDataCache ()

/// Keychain storage used to store and retrieve receipt data of multiple applications.
@property (readonly, nonatomic) BZRKeychainStorageRoute *keychainStorageRoute;

@end

/// Storage key to which the cached receipt data is written to.
NSString * const kReceiptDataKey = @"receiptData";

@implementation BZRReceiptDataCache

- (instancetype)initWithKeychainStorageRoute:(BZRKeychainStorageRoute *)keychainStorageRoute {
  if (self = [super init]) {
    _keychainStorageRoute = keychainStorageRoute;
  }
  return self;
}

- (BOOL)storeReceiptData:(nullable NSData *)receiptData
     applicationBundleID:(NSString *)applicationBundleID error:(NSError * __autoreleasing *)error {
  return [self.keychainStorageRoute setValue:receiptData forKey:kReceiptDataKey
                                 serviceName:applicationBundleID error:error];
}

- (nullable NSData *)receiptDataForApplicationBundleID:(NSString *)bundleID
                                                 error:(NSError * __autoreleasing *)error {
  return (NSData *)[self.keychainStorageRoute valueForKey:kReceiptDataKey serviceName:bundleID
                                                    error:error];
}

@end

NS_ASSUME_NONNULL_END
