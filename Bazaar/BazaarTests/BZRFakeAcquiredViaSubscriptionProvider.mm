// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeAcquiredViaSubscriptionProvider.h"

#import "BZRKeychainStorage.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeAcquiredViaSubscriptionProvider

@synthesize productsAcquiredViaSubscription = _productsAcquiredViaSubscription;

- (instancetype)init {
  BZRKeychainStorage *keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  if (self = [super initWithKeychainStorage:keychainStorage]) {
    _productsAcquiredViaSubscription = [NSSet set];
  }
  return self;
}

- (NSSet<NSString *> *)productsAcquiredViaSubscription {
  return _productsAcquiredViaSubscription;
}

- (void)setProductsAcquiredViaSubscription:(NSSet<NSString *> *)productsAcquiredViaSubscription {
  _productsAcquiredViaSubscription = productsAcquiredViaSubscription;
}

@end

NS_ASSUME_NONNULL_END
