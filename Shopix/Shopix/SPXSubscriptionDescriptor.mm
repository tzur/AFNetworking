// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionDescriptor

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier {
  if (self = [super init]) {
    _productIdentifier = [productIdentifier copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
