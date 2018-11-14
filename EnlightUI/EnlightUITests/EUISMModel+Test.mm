// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel+Test.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <Bazaar/BZRReceiptModel.h>

NS_ASSUME_NONNULL_BEGIN

@implementation EUISMModel (Test)

static NSString * const dummyProductID = @"com.lightricks.EnlightEditor_V4.PA.1M.ES_1M.ES";

+ (NSDictionary *)dummyProductDictionary {
  return @{
    @"identifier": dummyProductID,
    @"productType": @(1)
  };
}

+ (NSDictionary *)dummyBzrPendingRenewalInfoDictionary {
  return @{@"isInBillingRetryPeriod": @NO, @"willAutoRenew": @YES};
}

+ (NSDictionary *)dummyBzrSubscriptionDictionary {
  auto now = [NSDate date];
  auto bzrPendingRenewalInfo = [[BZRSubscriptionPendingRenewalInfo alloc]
                                initWithDictionary:[self dummyBzrPendingRenewalInfoDictionary]
                                error:nil];
  return @{
    @"isExpired": @NO,
    @"expirationDateTime": now,
    @"pendingRenewalInfo": bzrPendingRenewalInfo,
    @"productId": dummyProductID,
    @"originalTransactionId": @"dummyTransactionID",
    @"originalPurchaseDateTime": now,
  };
}

+ (instancetype)modelWithSingleAppSubscriptionForApplication:(EUISMApplication *)application {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary] error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:[self dummyBzrSubscriptionDictionary] error:nil];
  return [[EUISMModel alloc] initWithCurrentApplication:application
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

+ (instancetype)modelWithEcoSystemSubscription {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary] error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeEcoSystem];
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:[self dummyBzrSubscriptionDictionary] error:nil];
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

+ (instancetype)modelWithBillingIssues:(BOOL)billingIssues {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary] error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto pendingRenewalInfoDictionary = [self dummyBzrPendingRenewalInfoDictionary].mutableCopy;
  pendingRenewalInfoDictionary[@"isInBillingRetryPeriod"] = @(billingIssues);
  auto bzrPendingRenewalInfo = [[BZRSubscriptionPendingRenewalInfo alloc]
                                initWithDictionary:pendingRenewalInfoDictionary
                                error:nil];
  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"pendingRenewalInfo"] = bzrPendingRenewalInfo;
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

+ (instancetype)modelWithBillingPeriod:(BZRBillingPeriod *)billingPeriod expired:(BOOL)expired {
  auto currentProductInfo = [EUISMModel dummyProductInfoWithBillingPeriod:billingPeriod];
  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"isExpired"] = @(expired);
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

+ (EUISMProductInfo *)dummyProductInfoWithBillingPeriod:(BZRBillingPeriod *)billingPeriod {
  auto productDictionary = [self dummyProductDictionary].mutableCopy;
  productDictionary[@"billingPeriod"] = billingPeriod;
  auto product = [[BZRProduct alloc] initWithDictionary:productDictionary error:nil];
  return [[EUISMProductInfo alloc] initWithProduct:product
                                  subscriptionType:EUISMSubscriptionTypeSingleApp];
}

+ (instancetype)modelWithCurrentProductID:(NSString *)productID {
  auto productDictionary = [self dummyProductDictionary].mutableCopy;
  productDictionary[@"identifier"] = productID;
  auto product = [[BZRProduct alloc] initWithDictionary:productDictionary error:nil];
  auto productInfo = [[EUISMProductInfo alloc] initWithProduct:product
                                              subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"productId"] = productID;
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{productID: productInfo}];
}

+ (instancetype)modelWithPendingProductID:(NSString *)pendingProductID {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary] error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto pendingProductDictionary = [self dummyProductDictionary].mutableCopy;
  pendingProductDictionary[@"identifier"] = pendingProductID;
  auto pendingProduct = [[BZRProduct alloc] initWithDictionary:pendingProductDictionary error:nil];
  auto pendingProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:pendingProduct
                             subscriptionType:EUISMSubscriptionTypeSingleApp];
  auto productsInfo = @{dummyProductID: currentProductInfo, pendingProductID: pendingProductInfo};

  auto pendingRenewalInfoDictionary = [self dummyBzrPendingRenewalInfoDictionary].mutableCopy;
  pendingRenewalInfoDictionary[@"expectedRenewalProductId"] = pendingProductID;
  auto bzrPendingRenewalInfo = [[BZRSubscriptionPendingRenewalInfo alloc]
                                initWithDictionary:pendingRenewalInfoDictionary
                                error:nil];
  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"pendingRenewalInfo"] = bzrPendingRenewalInfo;
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:productsInfo];
}

+ (instancetype)modelWithNoSubscription {
  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:nil subscriptionGroupProductsInfo:@{}];
}

+ (instancetype)modelWithAutoRenewal:(BOOL)autoRenewal {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary] error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto pendingRenewalInfoDictionary = [self dummyBzrPendingRenewalInfoDictionary].mutableCopy;
  pendingRenewalInfoDictionary[@"willAutoRenew"] = @(autoRenewal);
  auto bzrPendingRenewalInfo = [[BZRSubscriptionPendingRenewalInfo alloc]
                                initWithDictionary:pendingRenewalInfoDictionary
                                error:nil];
  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"pendingRenewalInfo"] = bzrPendingRenewalInfo;
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

+ (instancetype)modelWithExpirationTime:(NSDate *)expirationTime {
  auto product = [[BZRProduct alloc] initWithDictionary:[self dummyProductDictionary]
                                                  error:nil];
  auto currentProductInfo = [[EUISMProductInfo alloc]
                             initWithProduct:product
                             subscriptionType:EUISMSubscriptionTypeSingleApp];

  auto subscriptionDictionary = [self dummyBzrSubscriptionDictionary].mutableCopy;
  subscriptionDictionary[@"expirationDateTime"] = expirationTime;
  auto bzrSubscription = [[BZRReceiptSubscriptionInfo alloc]
                          initWithDictionary:subscriptionDictionary error:nil];

  return [[EUISMModel alloc] initWithCurrentApplication:$(EUISMApplicationPhotofox)
                                currentSubscriptionInfo:bzrSubscription
                          subscriptionGroupProductsInfo:@{dummyProductID: currentProductInfo}];
}

@end

NS_ASSUME_NONNULL_END
