// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRSharedUserInfoReader.h"

#import "BZRKeychainStorage.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRReceiptValidationStatusCache.h"
#import "BZRTimeProvider.h"

@implementation BZRSharedUserInfoReader

- (BOOL)isSubscriberOfAppWithBundleIdentifier:(NSString *)bundleIdentifier {
  BZRReceiptValidationStatusCache *receiptValidationStatusCache =
      [self receiptValidationStatusCacheForAppWithBundleIdentifier:bundleIdentifier];
  BZRReceiptValidationStatusCacheEntry *cache = [receiptValidationStatusCache loadCacheEntry:nil];
  BZRReceiptSubscriptionInfo *subscription = cache.receiptValidationStatus.receipt.subscription;

  return subscription && !subscription.isExpired;
}

- (BZRReceiptValidationStatusCache *)receiptValidationStatusCacheForAppWithBundleIdentifier:
    (NSString *)bundleIdentifier {
  auto keychainStorage =
      [[BZRKeychainStorage alloc] initWithAccessGroup:[BZRKeychainStorage defaultSharedAccessGroup]
                                              service:bundleIdentifier];
  return [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorage];
}

@end
