// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionDescriptor.h"

#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRProductsInfoProvider.h>
#import <LTKit/NSArray+Functional.h>

#import "BZRBillingPeriod+ProductIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXSubscriptionDescriptor

+ (NSArray<SPXSubscriptionDescriptor *> *)
    descriptorsWithProductIdentifiers:(NSArray<NSString *> *)productIdentifiers
    discountPercentage:(NSUInteger)discountPercentage {
  return [productIdentifiers
          lt_map:^SPXSubscriptionDescriptor *(NSString *productIdentifier) {
            return [[SPXSubscriptionDescriptor alloc] initWithProductIdentifier:productIdentifier
                                                             discountPercentage:discountPercentage];
          }];
}

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier {
  return [self initWithProductIdentifier:productIdentifier discountPercentage:0];
}

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage {
  id<BZRProductsInfoProvider> productsInfoProvider =
      [JSObjection defaultInjector][@protocol(BZRProductsInfoProvider)];
  LTAssert(productsInfoProvider, @"BZRProductsInfoProvider is not injected properly, make sure "
           "Objection's default injector has binding for this protocol");
  return [self initWithProductIdentifier:productIdentifier discountPercentage:discountPercentage
                    productsInfoProvider:productsInfoProvider];
}

- (instancetype)initWithProductIdentifier:(NSString *)productIdentifier
                       discountPercentage:(NSUInteger)discountPercentage
                     productsInfoProvider:(id<BZRProductsInfoProvider>)productsInfoProvider {
  LTParameterAssert(discountPercentage < 100, @"Subscription's discount must be in range [0, 100) "
                    "got: %lu", (unsigned long)discountPercentage);
  if (self = [super init]) {
    _productIdentifier = [productIdentifier copy];
    _billingPeriod = [BZRBillingPeriod spx_billingPeriodWithProductIdentifier:productIdentifier];
    _discountPercentage = discountPercentage;
    _isMultiAppSubscription = [productsInfoProvider isMultiAppSubscription:productIdentifier];
  }
  return self;
}

- (void)setPriceInfo:(nullable BZRProductPriceInfo *)priceInfo {
  _priceInfo = priceInfo;

  // \c priceInfo.fullPrice is deprecated and will be removed in the upcoming Bazaar versions.
  // \c discountPercentage should replace \c priceInfo.fullPrice by giving a custom discount and
  // concluding the original full price from \c priceInfo.price.
  if (priceInfo.fullPrice && self.discountPercentage) {
    LogError(@"The subscripton product with the identifier (%@) has a conflict between the given "
             "custom subscription's discount (%f) and its deprecated property fullPrice (%@). "
             "Please don't assign a custom discount to an old-format subscription products.",
             self.productIdentifier, self.discountPercentage, priceInfo.fullPrice);
  }
}

@end

NS_ASSUME_NONNULL_END
