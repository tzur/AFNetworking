// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRStoreKitRequestsFactory.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRStoreKitRequestsFactory

+ (BZRStoreKitRequestsFactory *)defaultFactory {
  return [[BZRStoreKitRequestsFactory alloc] init];
}

- (SKProductsRequest *)productsRequestWithIdentifiers:
    (NSSet<NSString *> *)productIdentifiers {
  return [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
}

- (SKReceiptRefreshRequest *)receiptRefreshRequest {
  return [[SKReceiptRefreshRequest alloc] init];
}

@end

NS_ASSUME_NONNULL_END
