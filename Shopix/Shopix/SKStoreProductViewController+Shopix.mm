// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "SKStoreProductViewController+Shopix.h"

#import <AppsFlyerLib/AppsFlyerTracker.h>

NS_ASSUME_NONNULL_BEGIN

/// Cross promotion tracker that uses AppsFlyer.
@interface SPXAppsFlyerCrossPromotionTracker : NSObject <SPXCrossPromotionTracker>
@end

@implementation SPXAppsFlyerCrossPromotionTracker

- (void)trackWithProductID:(NSString *)productID campaign:(NSString *)campaign
                completion:(SPXCrossPromotionTrackerCompletion)completion {
  [AppsFlyerCrossPromotionHelper trackAndOpenStore:productID campaign:campaign paramters:nil
                                         openStore:completion];
}

@end

static NSString *SPXLastBundleComponent() {
  // Bundle identifier should always exist, since all apps must have a bundle identifier configured
  // in their main bundle.
  auto bundleIdentifier = nn([NSBundle mainBundle].bundleIdentifier, @"StoreProductController");
  return [bundleIdentifier componentsSeparatedByString:@"."].lastObject;
}

static NSString *SPXCampaignTokenForCampaign(NSString *campaign) {
  auto lastBundleComponent = SPXLastBundleComponent();
  return [NSString stringWithFormat:@"%@_%@", lastBundleComponent, campaign];
}

void SPXTrackProductDisplay(id<SPXCrossPromotionTracker> tracker, NSNumber *productID,
                            NSString *campaign, LTSuccessOrErrorBlock _Nullable completion) {
  auto campaignToken = SPXCampaignTokenForCampaign(campaign);
  [tracker trackWithProductID:productID.stringValue campaign:campaignToken
                   completion:^(NSURLSession *urlSession, NSURL *clickURL) {
                     auto dataTask = [urlSession dataTaskWithURL:clickURL
                                               completionHandler:^(NSData * _Nullable,
                                                                   NSURLResponse * _Nullable,
                                                                   NSError * _Nullable error) {
                                                 if (completion) {
                                                   completion(!error, error);
                                                 }
                                               }];
                     [dataTask resume];
                   }];
}

void SPXTrackProductDisplay(NSNumber *productID, NSString *campaign,
                            LTSuccessOrErrorBlock _Nullable completion) {
  auto tracker = [[SPXAppsFlyerCrossPromotionTracker alloc] init];
  SPXTrackProductDisplay(tracker, productID, campaign, completion);
}

@implementation SKStoreProductViewController (Shopix)

- (void)spx_loadProductWithProductID:(NSNumber *)productID campaign:(NSString *)campaign
                          completion:(nullable LTSuccessOrErrorBlock)completion {
  static const auto kLightricksAffiliateToken = @"1l3vqae";

  return [self loadProductWithParameters:@{
    SKStoreProductParameterITunesItemIdentifier: productID,
    SKStoreProductParameterAffiliateToken: kLightricksAffiliateToken,
    SKStoreProductParameterCampaignToken: SPXCampaignTokenForCampaign(campaign),
    SKStoreProductParameterProviderToken: SPXLastBundleComponent()
  } completionBlock:completion];
}

@end

NS_ASSUME_NONNULL_END
