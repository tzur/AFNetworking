// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRSharedUserInfoReader.h"

#import "BZRKeychainStorage.h"
#import "BZRKeychainStorageRoute.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"

@implementation BZRSharedUserInfoReader

- (BOOL)isSubscriberOfAppWithBundleIdentifier:(NSString *)bundleIdentifier {
  BZRReceiptValidationStatusCache *receiptValidationStatusCache =
      [self receiptValidationStatusCacheForAppWithBundleIdentifier:bundleIdentifier];
  BZRReceiptValidationStatusCacheEntry *cache =
      [receiptValidationStatusCache loadCacheEntryOfApplicationWithBundleID:bundleIdentifier
                                                                      error:nil];
  BZRReceiptSubscriptionInfo *subscription = cache.receiptValidationStatus.receipt.subscription;

  return subscription && !subscription.isExpired;
}

- (BZRReceiptValidationStatusCache *)receiptValidationStatusCacheForAppWithBundleIdentifier:
    (NSString *)bundleIdentifier {
  auto keychainStorageRoute =
      [[BZRKeychainStorageRoute alloc]
       initWithAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
       serviceNames:@[bundleIdentifier].lt_set];
  return [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];
}

@end
