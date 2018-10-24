// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "EUISMYourPlanViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProduct.h>
#import <Bazaar/BZRReceiptModel.h>

#import "EUISMModel.h"

NS_ASSUME_NONNULL_BEGIN

using namespace eui;

@implementation EUISMYourPlanViewModel

@synthesize body = _body;
@synthesize currentAppThumbnailURL = _currentAppThumbnailURL;
@synthesize statusIconURL = _statusIconURL;
@synthesize subtitle = _subtitle;
@synthesize title = _title;

- (instancetype)initWithModelSignal:(RACSignal<EUISMModel *> *)modelSignal {
  if (self = [super init]) {
    RAC(self, statusIconURL) = [[[[modelSignal
        ignore:nil]
        map:^NSURL * _Nullable (EUISMModel *model) {
          return [EUISMYourPlanViewModel statusIconURLFromModel:model];
        }]
        startWith:nil]
        deliverOnMainThread];

    RAC(self, title) = [[[[modelSignal
        ignore:nil]
        map:^NSString *(EUISMModel *model) {
          return [EUISMYourPlanViewModel titleFromModel:model];
        }]
        startWith:@""]
        deliverOnMainThread];

    RAC(self, subtitle) = [[[[modelSignal
        ignore:nil]
        map:^NSString *(EUISMModel *model) {
          return [EUISMYourPlanViewModel subtitleFromModel:model];
        }]
        startWith:@""]
        deliverOnMainThread];

    RAC(self, body) = [[[[modelSignal
        ignore:nil]
        map:^NSString *(EUISMModel *model) {
          return [EUISMYourPlanViewModel bodyFromModel:model];
        }]
        startWith:@""]
        deliverOnMainThread];

    RAC(self, currentAppThumbnailURL) = [[[[modelSignal
        ignore:nil]
        map:^NSURL *(EUISMModel *model) {
          return model.currentApplication.thumbnailURL;
        }]
        startWith:nil]
        deliverOnMainThread];
  }
  return self;
}

+ (nullable NSURL *)statusIconURLFromModel:(EUISMModel *)model {
  auto _Nullable subscriptionInfo = model.currentSubscriptionInfo;
  if (subscriptionInfo && subscriptionInfo.pendingRenewalInfo &&
      subscriptionInfo.pendingRenewalInfo.isInBillingRetryPeriod) {
    return [NSURL URLWithString:@"exclamationMark"];
  }
  return nil;
}

+ (NSString *)titleFromModel:(EUISMModel *)model {
  auto _Nullable productInfo = [EUISMYourPlanViewModel relevantProductInfoFromModel:model];
  return productInfo.subscriptionType == EUISMSubscriptionTypeEcoSystem ?
      @"Enlight PRO Suite" : model.currentApplication.fullName;
}

+ (NSString *)subtitleFromModel:(EUISMModel *)model {
  auto _Nullable productInfo = [EUISMYourPlanViewModel relevantProductInfoFromModel:model];
  if (!productInfo || !model.currentSubscriptionInfo) {
    auto notAMemberSubtitle = _LDefault(@"You are not a member yet", @"Text shown when the user is "
                                        "not subscribed to the application");
    return notAMemberSubtitle;
  }
  auto _Nullable billingPeriod = productInfo.product.billingPeriod;
  auto isExpired = model.currentSubscriptionInfo.isExpired;
  auto expiredSubtitlePrefix = [self titleFromModel:model];

  if (billingPeriod) {
    auto expiredSubtitle = [expiredSubtitlePrefix stringByAppendingString:@" - "];
    if (billingPeriod.unit.value == BZRBillingPeriodUnitMonths) {
      if (billingPeriod.unitCount == 1) {
        auto month = _LDefault(@"1 Month", @"Text shown next to the application name when the "
                               "current subscription renews every month");
        auto monthlyExpiredSubtitle = [expiredSubtitle stringByAppendingString:month];
        auto monthlyMemberSubtitle = _LDefault(@"You are a Monthly member", @"Text shown when the "
                                               "user has a subscription to the application that "
                                               "renews every month");
        return isExpired ? monthlyExpiredSubtitle : monthlyMemberSubtitle;
      }
      if (billingPeriod.unitCount == 6) {
        auto sixMonths = _LDefault(@"6 Months", @"Text shown next to the application name when the "
                                   "current subscription renews every 6 months");
        auto biyearlyExpiredSubtitle = [expiredSubtitle stringByAppendingString:sixMonths];
        auto biyearlyMemberSubtitle = _LDefault(@"You are a Biyearly member", @"Text shown when "
                                                "the user has a subscription to the application "
                                                "that renews every six months");
        return isExpired ? biyearlyExpiredSubtitle : biyearlyMemberSubtitle;
      }
    } else if (billingPeriod.unit.value == BZRBillingPeriodUnitYears) {
      if (billingPeriod.unitCount == 1) {
        auto year = _LDefault(@"1 Year", @"Text shown next to the application name when the "
                               "current subscription renews every year");
        auto yearlyExpiredSubtitle = [expiredSubtitle stringByAppendingString:year];
        auto yearlyMember = _LDefault(@"You are a Yearly member", @"Text shown when the user has a "
                                      "subscription to the application that renews every year");
        return isExpired ? yearlyExpiredSubtitle : yearlyMember;
      }
    }
  }

  auto memberSubtitle = _LDefault(@"You are a member", @"Text shown when the user is subscribed to "
                                  "the application");
  auto expiredSubtitle = expiredSubtitlePrefix;
  return isExpired ? expiredSubtitle : memberSubtitle;
}

+ (nullable EUISMProductInfo *)relevantProductInfoFromModel:(EUISMModel *)model {
  return model.pendingProductInfo ?: model.currentProductInfo;
}

+ (NSString *)bodyFromModel:(EUISMModel *)model {
  auto subscriptionInfo = model.currentSubscriptionInfo;
  if (!subscriptionInfo) {
    return @"";
  }

  auto expirationDate = subscriptionInfo.expirationDateTime;
  auto dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.locale = [NSLocale currentLocale];

  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  auto expirationTime = [dateFormatter stringFromDate:expirationDate];

  auto bodyPrefix = _LDefault(@"Ends", @"Text shown before the subscription expiration date text "
                              "if the subscription won't renew automatically at expiration. For "
                              "example: Ends 1 Jan 2020");

  if (subscriptionInfo.isExpired) {
    bodyPrefix = _LDefault(@"Expired", @"Text shown before the subscription expiration date text "
                           "if the subscription already expired and didn't renew. For example: "
                           "Expired 1 Jan 2018");
  }
  else if (subscriptionInfo.pendingRenewalInfo &&
           subscriptionInfo.pendingRenewalInfo.willAutoRenew) {
    bodyPrefix = _LDefault(@"Renews", @"Text shown before the subscription expiration date text if "
                           "the subscription will renew automatically at expiration. For example: "
                           "Renews 1 Jan 2020");
  }
  return [NSString stringWithFormat:@"%@ %@", bodyPrefix, expirationTime];
}

@end

NS_ASSUME_NONNULL_END
