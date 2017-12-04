// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionButtonPressedEvent.h"

#import <Bazaar/BZRProductPriceInfo.h>

#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionButtonPressedEvent

- (instancetype)initWithSubscriptionDescriptor:(SPXSubscriptionDescriptor *)subscriptionDescriptor {
  if (self = [super init]) {
    _productIdentifier = [subscriptionDescriptor.productIdentifier copy];
    _price = subscriptionDescriptor.priceInfo.price;
    _localeIdentifier = subscriptionDescriptor.priceInfo.localeIdentifier;
    auto locale =
        [NSLocale localeWithLocaleIdentifier:subscriptionDescriptor.priceInfo.localeIdentifier];
    _currencyCode = locale.currencyCode;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
