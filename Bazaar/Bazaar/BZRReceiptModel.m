// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptModel.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark BZRReceiptInAppPurchaseInfo
#pragma mark -

@implementation BZRReceiptInAppPurchaseInfo
@end

#pragma mark -
#pragma mark BZRReceiptSubscriptionInfo
#pragma mark -

@implementation BZRReceiptSubscriptionInfo

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptSubscriptionInfo, lastPurchaseDateTime),
      @instanceKeypath(BZRReceiptSubscriptionInfo, cancellationDateTime)
    ]];
  });

  return nullablePropertyKeys;
}

@end

#pragma mark -
#pragma mark BZRReceiptInfo
#pragma mark -

@implementation BZRReceiptInfo

+ (NSSet<NSString *> *)nullablePropertyKeys {
  static NSSet<NSString *> *nullablePropertyKeys;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nullablePropertyKeys = [NSSet setWithArray:@[
      @instanceKeypath(BZRReceiptInfo, inAppPurchases),
      @instanceKeypath(BZRReceiptInfo, subscription)
    ]];
  });

  return nullablePropertyKeys;
}

@end

NS_ASSUME_NONNULL_END
