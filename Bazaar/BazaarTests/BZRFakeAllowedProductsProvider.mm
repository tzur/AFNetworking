// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeAllowedProductsProvider.h"

#import "BZRFakeAcquiredViaSubscriptionProvider.h"
#import "BZRFakeCachedReceiptValidationStatusProvider.h"
#import "BZRProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeAllowedProductsProvider

@synthesize allowedProducts = _allowedProducts;

- (instancetype)init {
  id<BZRProductsProvider> productsProvider = OCMProtocolMock(@protocol(BZRProductsProvider));
  OCMStub([productsProvider fetchProductList]).andReturn([RACSignal empty]);
  auto validationStatusProvider = [[BZRFakeCachedReceiptValidationStatusProvider alloc] init];
  auto acquiredViaSubscriptionProvider = [[BZRFakeAcquiredViaSubscriptionProvider alloc] init];
  return [super initWithProductsProvider:productsProvider
                validationStatusProvider:validationStatusProvider
         acquiredViaSubscriptionProvider:acquiredViaSubscriptionProvider];
}

@end

NS_ASSUME_NONNULL_END
