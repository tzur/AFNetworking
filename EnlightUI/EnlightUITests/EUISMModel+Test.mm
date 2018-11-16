// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+Test.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRReceiptModel.h>

NS_ASSUME_NONNULL_BEGIN

@implementation BZRBillingPeriod (EUISMTest)

+ (instancetype)eui_billingPeriodMonthly {
  return [[BZRBillingPeriod alloc] initWithDictionary:@{
    @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitMonths),
    @instanceKeypath(BZRBillingPeriod, unitCount): @(1)
  } error:nil];
}

+ (instancetype)eui_billingPeriodBiyearly {
  return [[BZRBillingPeriod alloc] initWithDictionary:@{
    @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitMonths),
    @instanceKeypath(BZRBillingPeriod, unitCount): @(6)
  } error:nil];
}

+ (instancetype)eui_billingPeriodYearly {
  return [[BZRBillingPeriod alloc] initWithDictionary:@{
    @instanceKeypath(BZRBillingPeriod, unit): $(BZRBillingPeriodUnitYears),
    @instanceKeypath(BZRBillingPeriod, unitCount): @(1)
  } error:nil];
}

@end

@implementation EUISMModel (Test)

static NSString * const monthlyProductID = @"com.lightricks.EnlightEditor_V4.PA.1M.ES_1M.ES";
static NSString * const yearlyProductID = @"com.lightricks.EnlightEditor_V4.PA.1M.ES_1Y.ES";
static NSString * const dummyProductID = monthlyProductID;

+ (BZRProduct *)dummyProduct {
  return nn([[BZRProduct alloc] initWithDictionary:@{
    @instanceKeypath(BZRProduct, identifier): dummyProductID,
    @instanceKeypath(BZRProduct, productType): @(1)
  } error:nil]);
}

+ (BZRSubscriptionPendingRenewalInfo *)dummyBzrPendingRenewalInfo {
  return nn([[BZRSubscriptionPendingRenewalInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, isInBillingRetryPeriod): @NO,
    @instanceKeypath(BZRSubscriptionPendingRenewalInfo, willAutoRenew): @YES
  } error:nil]);
}

+ (BZRReceiptSubscriptionInfo *)dummyBzrSubscription {
  auto now = [NSDate date];
  auto bzrPendingRenewalInfo = [EUISMModel dummyBzrPendingRenewalInfo];
  return nn([[BZRReceiptSubscriptionInfo alloc] initWithDictionary:@{
    @instanceKeypath(BZRReceiptSubscriptionInfo, isExpired): @NO,
    @instanceKeypath(BZRReceiptSubscriptionInfo, expirationDateTime): now,
    @instanceKeypath(BZRReceiptSubscriptionInfo, pendingRenewalInfo): bzrPendingRenewalInfo,
    @instanceKeypath(BZRReceiptSubscriptionInfo, productId): dummyProductID,
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalTransactionId): @"dummyTransactionID",
    @instanceKeypath(BZRReceiptSubscriptionInfo, originalPurchaseDateTime): now,
  } error:nil]);
}

+ (BZRProductPriceInfo *)priceInfoWithPrice:(NSDecimalNumber *)price {
  return nn([[BZRProductPriceInfo alloc] initWithDictionary: @{
    @instanceKeypath(BZRProductPriceInfo, price): price,
    @instanceKeypath(BZRProductPriceInfo, localeIdentifier): @"en_US"
  } error:nil]);
}

+ (instancetype)modelWithSingleAppSubscriptionForApplication:(EUISMApplication *)application {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  return [[EUISMModel alloc] initWithCurrentApplication:application
                                currentSubscriptionInfo:[EUISMModel dummyBzrSubscription]
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithEcoSystemSubscription {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeEcoSystem];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:[EUISMModel dummyBzrSubscription]
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithBillingIssues:(BOOL)billingIssues {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo,
                                                          pendingRenewalInfo)
      withValue:[[EUISMModel dummyBzrPendingRenewalInfo]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRSubscriptionPendingRenewalInfo,
                                                          isInBillingRetryPeriod)
      withValue:@(billingIssues)]];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithBillingPeriod:(BZRBillingPeriod *)billingPeriod expired:(BOOL)expired {
  auto dummyProduct = [[EUISMModel dummyProduct]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, billingPeriod)
      withValue:billingPeriod];
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:dummyProduct
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo, isExpired)
      withValue:@(expired)];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithCurrentProductID:(NSString *)productID {
  auto product = [[EUISMModel dummyProduct]
                  modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, identifier)
                  withValue:productID];
  auto productInfo = [[EUISMProductInfo alloc] initWithProduct:product
                                              subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo, productId)
      withValue:productID];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{productID: productInfo}];
}

+ (instancetype)modelWithPendingProductID:(NSString *)pendingProductID {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto pendingProductInfo = [[EUISMProductInfo alloc] initWithProduct:[[EUISMModel dummyProduct]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, identifier)
      withValue:pendingProductID] subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto productsInfo = @{dummyProductID: dummyProductInfo, pendingProductID: pendingProductInfo};

  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo,
                                                          pendingRenewalInfo)
      withValue:[[EUISMModel dummyBzrPendingRenewalInfo]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRSubscriptionPendingRenewalInfo,
                                                          expectedRenewalProductId)
      withValue:pendingProductID]];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:productsInfo];
}

+ (instancetype)modelWithNoSubscription {
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:nil subscriptionGroupProductsInfo:@{}];
}

+ (instancetype)modelWithAutoRenewal:(BOOL)autoRenewal {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo,
                                                          pendingRenewalInfo)
      withValue:[[EUISMModel dummyBzrPendingRenewalInfo]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRSubscriptionPendingRenewalInfo,
                                                          willAutoRenew)
      withValue:@(autoRenewal)]];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithExpirationTime:(NSDate *)expirationTime {
  auto dummyProductInfo = [[EUISMProductInfo alloc] initWithProduct:[EUISMModel dummyProduct]
                                                   subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo,
                                                          expirationDateTime)
      withValue:expirationTime];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: dummyProductInfo}];
}

+ (instancetype)modelWithPromotedProductSavePercent:(NSUInteger)savePercent {
  auto monthlyBillingPeriod = [BZRBillingPeriod eui_billingPeriodMonthly];
  return [EUISMModel modelWithAvailableYearlyUpradeSavePercent:savePercent
                                                 billingPeriod:monthlyBillingPeriod];
}

+ (instancetype)modelWithAvailableYearlyUpradeSavePercent:(NSUInteger)savePercent
                                            billingPeriod:(BZRBillingPeriod *)billingPeriod {
  LTAssert(savePercent <= 100, @"savePercent can't be larger than 100");
  auto price = [NSDecimalNumber decimalNumberWithString:@"100"];
  auto yearlyPeriod = [BZRBillingPeriod eui_billingPeriodYearly];
  auto productID = [billingPeriod isEqual:yearlyPeriod] ? yearlyProductID : monthlyProductID;

  auto product = [[[[EUISMModel dummyProduct]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, identifier)
      withValue:productID]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, billingPeriod)
      withValue:billingPeriod]
      /* TODO:(Dekel) fix once BZR exposes a more accurate price */
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, priceInfo)
      withValue:[EUISMModel priceInfoWithPrice:price]];
  auto productInfo = [[EUISMProductInfo alloc] initWithProduct:product
                                              subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto yearlyPriceString = [NSString stringWithFormat:@"%lu", 12 * (100 - savePercent)];
  auto yearlyPrice = [NSDecimalNumber decimalNumberWithString:yearlyPriceString];
  auto yearlyProduct = [[[[EUISMModel dummyProduct]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, identifier)
      withValue:yearlyProductID]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, billingPeriod)
      withValue:yearlyPeriod]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRProduct, priceInfo)
      withValue:[EUISMModel priceInfoWithPrice:yearlyPrice]];
  auto yearlyProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:yearlyProduct
                             subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto subscriptionGroup = @{
    productID: productInfo,
    yearlyProductID: yearlyProductInfo
  };

  auto bzrSubscription = [[EUISMModel dummyBzrSubscription]
      modelByOverridingPropertyAtKeypath:@instanceKeypath(BZRReceiptSubscriptionInfo, productId)
      withValue:productID];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:subscriptionGroup];
}

@end

NS_ASSUME_NONNULL_END
