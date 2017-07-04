// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRFakeAllowedProductsProvider.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRFakeAllowedProductsProvider

- (instancetype)init {
  if (self = [super init]) {
    _eventsSignal = [RACSubject subject];
    _allowedProducts = [NSSet set];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
