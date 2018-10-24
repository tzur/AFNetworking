// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>

NS_ASSUME_NONNULL_BEGIN

/// Enum for Enlight ecosystem applications that the subscription management componen supports.
LTEnumImplement(NSUInteger, EUISMApplication,
  EUISMApplicationPhotofox,
  EUISMApplicationVideoleap,
  EUISMApplicationQuickshot,
  EUISMApplicationPixaloop
);

@implementation EUISMApplication (Properties)

- (NSString *)fullName {
  NSString *givenName;
  switch (self.value) {
    case EUISMApplicationPhotofox:
      givenName = @"Photofox";
      break;
    case EUISMApplicationVideoleap:
      givenName = @"Videoleap";
      break;
    case EUISMApplicationQuickshot:
      givenName = @"Quickshot";
      break;
    case EUISMApplicationPixaloop:
      givenName = @"Pixaloop";
      break;
  }
  return [@"Enlight " stringByAppendingString:givenName];
}

- (NSString *)bundleID {
  NSString *bundleIDSuffix;
  switch (self.value) {
    case EUISMApplicationPhotofox:
      bundleIDSuffix = @"Editor";
      break;
    case EUISMApplicationVideoleap:
      bundleIDSuffix = @"Video";
      break;
    case EUISMApplicationQuickshot:
      bundleIDSuffix = @"Photos";
      break;
    case EUISMApplicationPixaloop:
      bundleIDSuffix = @"Pixaloop";
      break;
  }
  return [@"com.lightricks.Enlight-" stringByAppendingString:bundleIDSuffix];
}

- (NSString *)urlScheme {
  switch (self.value) {
    case EUISMApplicationPhotofox:
      return @"photofox";
    case EUISMApplicationVideoleap:
      return @"videoleap";
    case EUISMApplicationQuickshot:
      return @"quickshot";
    case EUISMApplicationPixaloop:
      return @"pixaloop";
  }
}

- (NSURL *)thumbnailURL {
  NSString *thumbnailName;
  switch (self.value) {
    case EUISMApplicationPhotofox:
      thumbnailName = @"PF";
      break;
    case EUISMApplicationVideoleap:
      thumbnailName = @"VL";
      break;
    case EUISMApplicationQuickshot:
      thumbnailName = @"QS";
      break;
    case EUISMApplicationPixaloop:
      thumbnailName = @"PX";
      break;
  }
  return nn([NSURL URLWithString:thumbnailName]);
}

@end

@implementation EUISMProductInfo

- (instancetype)initWithProduct:(BZRProduct *)product
               subscriptionType:(EUISMSubscriptionType)subscriptionType {
  if (self = [super init]) {
    _product = product;
    _subscriptionType = subscriptionType;
  }
  return self;
}

@end

@implementation EUISMModel

- (instancetype)initWithCurrentApplication:(EUISMApplication *)currentApplication
    currentSubscriptionInfo:(nullable BZRReceiptSubscriptionInfo *)currentSubscriptionInfo
    currentProductInfo:(nullable EUISMProductInfo *)currentProductInfo
    pendingProductInfo:(nullable EUISMProductInfo *)pendingProductInfo
    subscriptionGroupProductsInfo:(NSSet<EUISMProductInfo *> *)subscriptionGroupProductsInfo {
  if (self = [super init]) {
    _currentApplication = currentApplication;
    _currentSubscriptionInfo = currentSubscriptionInfo;
    _currentProductInfo = currentProductInfo;
    _pendingProductInfo = pendingProductInfo;
    _subscriptionGroupProductsInfo = subscriptionGroupProductsInfo;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
