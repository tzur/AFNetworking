// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsViewModel.h"

#import <Bazaar/BZRBillingPeriod.h>
#import <Bazaar/BZRProductPriceInfo.h>
#import <LTKit/NSArray+Functional.h>

#import "NSDecimalNumber+Localization.h"
#import "SPXSubscriptionDescriptor.h"

NS_ASSUME_NONNULL_BEGIN

using namespace spx;

@interface SPXSubscriptionTermsViewModel ()

/// Optional attributed string that is presented before the terms text, used for a dynamic text such
/// as terms that depends on a specific subscription.
@property (strong, nonatomic, nullable) NSAttributedString *termsGistText;

/// Non-attributed version of the terms overview as provided on initialization.
@property (readonly, nonatomic) NSString *termsOverview;

/// URL to the full terms-of-use document.
@property (readonly, nonatomic) NSURL *fullTermsURL;

/// URL to the full privacy-policy document.
@property (readonly, nonatomic) NSURL *privacyPolicyURL;

/// Color for \c termsText.
@property (readonly, nonatomic) UIColor *termsTextColor;

/// Color for \c termsOfUseLink and \c privacyPolicyLink.
@property (readonly, nonatomic) UIColor *linksColor;

@end

@implementation SPXSubscriptionTermsViewModel

- (instancetype)initWithFullTerms:(NSURL *)fullTermsURL privacyPolicy:(NSURL *)privacyPolicyURL {
  return [self initWithTermsOverview:SPXSubscriptionTermsViewModel.defaultTermsOverview
                           fullTerms:fullTermsURL privacyPolicy:privacyPolicyURL];
}

- (instancetype)initWithTermsOverview:(NSString *)termsOverview fullTerms:(NSURL *)fullTermsURL
                        privacyPolicy:(NSURL *)privacyPolicyURL {
  return [self initWithTermsOverview:termsOverview fullTerms:fullTermsURL
                       privacyPolicy:privacyPolicyURL
                      termsTextColor:[UIColor colorWithWhite:1.0 alpha:0.6]
                          linksColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
}

- (instancetype)initWithTermsOverview:(NSString *)termsOverview
                            fullTerms:(NSURL *)fullTermsURL
                        privacyPolicy:(NSURL *)privacyPolicyURL
                       termsTextColor:(UIColor *)termsTextColor
                           linksColor:(UIColor *)linksColor {
  if (self = [super init]) {
    _termsOverview = [termsOverview copy];
    _fullTermsURL = fullTermsURL;
    _privacyPolicyURL = privacyPolicyURL;
    _termsTextColor = termsTextColor;
    _linksColor = linksColor;
  }
  return self;
}

#pragma mark -
#pragma mark SPXSubscriptionTermsViewModel
#pragma mark -

- (NSAttributedString *)termsText {
  auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = NSTextAlignmentCenter;
  paragraphStyle.lineHeightMultiple = 0.9;
  return [[NSMutableAttributedString alloc] initWithString:self.termsOverview attributes:@{
    NSForegroundColorAttributeName: self.termsTextColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightLight],
    NSParagraphStyleAttributeName: paragraphStyle
  }];
}

- (NSAttributedString *)termsOfUseLink {
  return [[NSAttributedString alloc] initWithString:@"Terms of Use" attributes:@{
    NSForegroundColorAttributeName: self.linksColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.fullTermsURL
  }];
}

- (NSAttributedString *)privacyPolicyLink {
  return [[NSAttributedString alloc] initWithString:@"Privacy" attributes:@{
    NSForegroundColorAttributeName: self.linksColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.privacyPolicyURL
  }];
}

- (void)updateTermsGistWithSubscriptions:
    (nullable NSArray<SPXSubscriptionDescriptor *> *)subscriptionDescriptors {
  [self unbindOnePaymentText];
  if (!subscriptionDescriptors) {
    return;
  }
  [self bindOnePaymentTextForDescriptors:subscriptionDescriptors];
}

- (void)unbindOnePaymentText {
  self.termsGistText = nil;
}

- (void)bindOnePaymentTextForDescriptors:(NSArray<SPXSubscriptionDescriptor *> *)descriptors {
  auto _Nullable foundSubscription =
      [descriptors lt_find:^BOOL(SPXSubscriptionDescriptor *descriptor) {
        return descriptor.billingPeriod.unit.value == BZRBillingPeriodUnitYears ||
          (descriptor.billingPeriod.unit.value == BZRBillingPeriodUnitMonths &&
           descriptor.billingPeriod.unitCount > 1);
      }];

  if (!foundSubscription) {
    return;
  }

  @weakify(self);
  RAC(self, termsGistText) = [[[RACObserve(foundSubscription, priceInfo)
      takeUntil:[self rac_signalForSelector:@selector(unbindOnePaymentText)]]
      map:^NSAttributedString *(BZRProductPriceInfo * _Nullable priceInfo) {
        @strongify(self);
        auto termsGistString = priceInfo ?
            [NSString stringWithFormat:SPXSubscriptionTermsViewModel.defaultTermsGistWithPrice,
             [priceInfo.price spx_localizedPriceForLocale:priceInfo.localeIdentifier]] :
            SPXSubscriptionTermsViewModel.defaultTermsGist;
        return [self termsGistTextForString:[@"* " stringByAppendingString:termsGistString]];
      }]
      deliverOnMainThread];
}

- (NSAttributedString *)termsGistTextForString:(NSString *)termsGistString {
  auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = NSTextAlignmentCenter;
  return [[NSAttributedString alloc] initWithString:termsGistString attributes:@{
    NSForegroundColorAttributeName: self.termsTextColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold],
    NSParagraphStyleAttributeName: paragraphStyle
  }];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

+ (NSString *)defaultTermsOverview {
  return _LDefault(@"Payment will be charged to your iTunes account at confirmation of purchase. "
    "Subscriptions will automatically renew unless auto-renew is turned off at least 24 hours "
    "before the end of the current period. Your account will be charged for renewal, in accordance "
    "with your plan, within 24 hours prior to the end of the current period. You can manage or "
    "turn off auto-renew in your Apple ID account settings any time after purchase.", @"Short "
    "terms of use shown to the user in the subscription screen.");
}

+ (NSString *)defaultTermsGist {
  return _LDefault(@"Billed in one payment", @"A note used to clarify that a subscription is "
                   "billed once.");
}

+ (NSString *)defaultTermsGistWithPrice {
  return _LDefault(@"Billed in one payment of %@", @"A note used to clarify that a subscription is "
                   "billed once and the subscription price. The %@ must appear in the translation "
                   "and will be replaced with the price. Example: Billed in one payment of $10");
}

@end

NS_ASSUME_NONNULL_END
