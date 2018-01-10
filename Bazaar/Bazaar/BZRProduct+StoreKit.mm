// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRProduct+StoreKit.h"

#import "BZRBillingPeriod+StoreKit.h"
#import "BZRProductPriceInfo+StoreKit.h"
#import "BZRSubscriptionIntroductoryDiscount+StoreKit.h"

NS_ASSUME_NONNULL_BEGIN

@implementation BZRProduct (StoreKit)

- (instancetype)productByAssociatingStoreKitProduct:(SKProduct *)storeKitProduct {
  LTParameterAssert([storeKitProduct.productIdentifier isEqualToString:self.identifier],
                    @"Trying to associate SKProduct (%@) with incorrect BZRProduct %@",
                    storeKitProduct.productIdentifier, self.identifier);

  auto priceInfo = [BZRProductPriceInfo productPriceInfoWithSKProduct:storeKitProduct];
  auto _Nullable billingPeriod = [BZRBillingPeriod billingPeriodForSKProduct:storeKitProduct] ?:
      self.billingPeriod;
  auto _Nullable introDiscount =
      [BZRSubscriptionIntroductoryDiscount introductoryDiscountForSKProduct:storeKitProduct] ?:
      self.introductoryDiscount;

  return [[[[self
      modelByOverridingProperty:@keypath(self, underlyingProduct) withValue:storeKitProduct]
      modelByOverridingProperty:@keypath(self, priceInfo) withValue:priceInfo]
      modelByOverridingProperty:@keypath(self, billingPeriod) withValue:billingPeriod]
      modelByOverridingProperty:@keypath(self, introductoryDiscount) withValue:introDiscount];
}

- (nullable SKPayment *)underlyingProduct {
  return objc_getAssociatedObject(self, @selector(underlyingProduct));
}

- (void)setUnderlyingProduct:(nullable SKProduct *)product {
  objc_setAssociatedObject(self, @selector(underlyingProduct), product,
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NS_ASSUME_NONNULL_END
