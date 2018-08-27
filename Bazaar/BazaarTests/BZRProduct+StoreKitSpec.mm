// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRProduct+StoreKit.h"

#import "BZRBillingPeriod+StoreKit.h"
#import "BZRProductPriceInfo+StoreKit.h"
#import "BZRSubscriptionIntroductoryDiscount+StoreKit.h"
#import "BZRTestUtils.h"

SpecBegin(BZRProduct_StoreKit)

__block BZRProduct *baseProduct;
__block SKProduct *storeKitProduct;

beforeEach(^{
  baseProduct = BZRProductWithIdentifier(@"foo");
  storeKitProduct = BZRMockedSKProductWithProperties(@"foo");
});

context(@"setting the underlying product", ^{
  it(@"should set the underlying product to the given StoreKit product", ^{
    auto productWithUnderlyingProduct =
        [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithUnderlyingProduct.underlyingProduct).to.beIdenticalTo(storeKitProduct);
  });
});

context(@"setting price info", ^{
  __block BZRProductPriceInfo *expectedPriceInfo;

  beforeEach(^{
    expectedPriceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRProductPriceInfo, price): storeKitProduct.price,
      @instanceKeypath(BZRProductPriceInfo, localeIdentifier):
          storeKitProduct.priceLocale.localeIdentifier
    } error:nil];
  });

  it(@"should set the price info to the price info provided by StoreKit", ^{
    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.priceInfo).to.equal(expectedPriceInfo);
  });

  it(@"should override the prefetched price info with the price info provided by StoreKit", ^{
    BZRProductPriceInfo *preFetchedPriceInfo = [[BZRProductPriceInfo alloc] initWithDictionary:@{
      @instanceKeypath(BZRProductPriceInfo, price): [[NSDecimalNumber alloc] initWithString:@"5"],
      @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"he_IL"
    } error:nil];
    baseProduct = [baseProduct modelByOverridingProperty:@keypath(baseProduct, priceInfo)
                                               withValue:preFetchedPriceInfo];

    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.priceInfo).to.equal(expectedPriceInfo);
  });
});

context(@"setting billing period", ^{
  __block BZRBillingPeriod *preFetchedBillingPeriod;

  beforeEach(^{
    preFetchedBillingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitWeeks),
      @instanceKeypath(BZRBillingPeriod, unitCount): @8
    } error:nil];
  });

  it(@"should set billing period to nil if not prefetched and not provided by StoreKit", ^{
    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.billingPeriod).to.beNil();
  });

  it(@"should not override prefetched billing period if not provided by StoreKit", ^{
    baseProduct = [baseProduct
        modelByOverridingProperty:@keypath(baseProduct, billingPeriod)
        withValue:preFetchedBillingPeriod];

    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.billingPeriod).to.equal(baseProduct.billingPeriod);
  });

  if (@available(iOS 11.2, *)) {
    context(@"subscription period property is available", ^{
      __block SKProductSubscriptionPeriod *subscriptionPeriod;
      __block BZRBillingPeriod *expectedBillingPeriod;

      beforeEach(^{
        subscriptionPeriod = OCMClassMock([SKProductSubscriptionPeriod class]);
        OCMStub([subscriptionPeriod unit]).andReturn(SKProductPeriodUnitMonth);
        OCMStub([subscriptionPeriod numberOfUnits]).andReturn(1);

        expectedBillingPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
          @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitMonths),
          @instanceKeypath(BZRBillingPeriod, unitCount): @1
        } error:nil];
      });

      it(@"should set billing period if provided by StoreKit", ^{
        OCMStub([storeKitProduct subscriptionPeriod]).andReturn(subscriptionPeriod);

        auto productWithMetadata =
            [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

        expect(productWithMetadata.billingPeriod).to.equal(expectedBillingPeriod);
      });

      it(@"should override prefetched billing period if provided by StoreKit", ^{
        baseProduct = [baseProduct
            modelByOverridingProperty:@keypath(baseProduct, billingPeriod)
            withValue:preFetchedBillingPeriod];
        OCMStub([storeKitProduct subscriptionPeriod]).andReturn(subscriptionPeriod);

        auto productWithMetadata =
            [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

        expect(productWithMetadata.billingPeriod).to.equal(expectedBillingPeriod);
      });
    });
  }
});

context(@"setting introductory discount", ^{
  __block BZRSubscriptionIntroductoryDiscount *preFetchedIntroductoryDiscount;

  beforeEach(^{
    auto preFetchedDiscountPeriod = [[BZRBillingPeriod alloc] initWithDictionary:@{
      @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitWeeks),
      @instanceKeypath(BZRBillingPeriod, unitCount): @8
    } error:nil];
    preFetchedIntroductoryDiscount =
        [[BZRSubscriptionIntroductoryDiscount alloc] initWithDictionary:@{
          @instanceKeypath(BZRSubscriptionIntroductoryDiscount, discountType):
              $(BZRIntroductoryDiscountTypePayAsYouGo),
          @instanceKeypath(BZRSubscriptionIntroductoryDiscount, price): [NSDecimalNumber one],
          @instanceKeypath(BZRSubscriptionIntroductoryDiscount, billingPeriod):
              preFetchedDiscountPeriod,
          @instanceKeypath(BZRSubscriptionIntroductoryDiscount, numberOfPeriods): @2
        } error:nil];
  });

  it(@"should set introductory discount to nil if not prefetched and not provided by StoreKit", ^{
    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.introductoryDiscount).to.beNil();
  });

  it(@"should not override the prefetched introductory discount if not provided by StoreKit", ^{
    baseProduct = [baseProduct
                   modelByOverridingProperty:@keypath(baseProduct, introductoryDiscount)
                   withValue:preFetchedIntroductoryDiscount];

    auto productWithMetadata = [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

    expect(productWithMetadata.introductoryDiscount).to.equal(preFetchedIntroductoryDiscount);
  });

  if (@available(iOS 11.2, *)) {
    context(@"introductory discount property is available", ^{
      __block SKProductDiscount *introductoryPrice;
      __block BZRSubscriptionIntroductoryDiscount *expectedIntroductoryDiscount;

      beforeEach(^{
        SKProductSubscriptionPeriod *discountPeriod =
            OCMClassMock([SKProductSubscriptionPeriod class]);
        OCMStub([discountPeriod unit]).andReturn(SKProductPeriodUnitMonth);
        OCMStub([discountPeriod numberOfUnits]).andReturn(1);

        introductoryPrice = OCMClassMock([SKProductDiscount class]);
        OCMStub([introductoryPrice paymentMode])
            .andReturn(SKProductDiscountPaymentModePayAsYouGo);
        OCMStub([introductoryPrice price]).andReturn([NSDecimalNumber one]);
        OCMStub([introductoryPrice priceLocale]).andReturn([NSLocale currentLocale]);
        OCMStub([introductoryPrice subscriptionPeriod]).andReturn(discountPeriod);
        OCMStub([introductoryPrice numberOfPeriods]).andReturn(2);

        expectedIntroductoryDiscount =
            [BZRSubscriptionIntroductoryDiscount
             introductoryDiscountWithSKProductDiscount:introductoryPrice];
      });

      it(@"should set introductory discount if provided by SKProduct", ^{
        OCMStub([storeKitProduct introductoryPrice]).andReturn(introductoryPrice);

        auto productWithMetadata =
            [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

        expect(productWithMetadata.introductoryDiscount).to.equal(expectedIntroductoryDiscount);
      });

      it(@"should override the prefetched introductory discount if provided by StoreKit", ^{
        OCMStub([storeKitProduct introductoryPrice]).andReturn(introductoryPrice);
        baseProduct = [baseProduct
                       modelByOverridingProperty:@keypath(baseProduct, introductoryDiscount)
                       withValue:preFetchedIntroductoryDiscount];

        auto productWithMetadata =
            [baseProduct productByAssociatingStoreKitProduct:storeKitProduct];

        expect(productWithMetadata.introductoryDiscount).to.equal(expectedIntroductoryDiscount);
      });
    });
  }
});

SpecEnd
