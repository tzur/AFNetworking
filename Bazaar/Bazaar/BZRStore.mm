// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStore.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRStore

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithConfiguration:(BZRStoreConfiguration __unused *)configuration {
  if (self = [super init]) {
    _errorsSignal = [RACSignal empty];
  }
  return self;
}

#pragma mark -
#pragma mark BZRProductsInfoProvider
#pragma mark -

- (nullable LTPath *)pathToContentOfProduct:(NSString __unused *)productIdentifier {
  return nil;
}

- (NSSet<NSString *> *)purchasedProducts {
  return [NSSet set];
}

- (NSSet<NSString *> *)acquiredViaSubscriptionProducts {
  return [NSSet set];
}

- (NSSet<NSString *> *)acquiredProducts {
  return [NSSet set];
}

- (NSSet<NSString *> *)allowedProducts {
  return [NSSet set];
}

- (NSSet<NSString *> *)downloadedContentProducts {
  return [NSSet set];
}

- (nullable BZRReceiptSubscriptionInfo *)subscriptionInfo {
  return nil;
}

#pragma mark -
#pragma mark BZRProductsManager
#pragma mark -

- (RACSignal *)purchaseProduct:(NSString __unused *)productIdentifier {
  return [RACSignal empty];
}

- (RACSignal *)fetchProductContent:(NSString __unused *)productIdentifier {
  return [RACSignal empty];
}

- (RACSignal *)deleteProductContent:(NSString __unused *)productIdentifier {
  return [RACSignal empty];
}

- (RACSignal *)refreshReceipt {
  return [RACSignal empty];
}

- (RACSignal *)productList {
  return [RACSignal empty];
}

@end

NS_ASSUME_NONNULL_END
