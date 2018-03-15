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
  return [[NSAttributedString alloc] initWithString:_LDefault(@"Terms of Use", @"Title of link to "
                                                              "terms of use document")
                                         attributes:@{
    NSForegroundColorAttributeName: self.linksColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.fullTermsURL
  }];
}

- (NSAttributedString *)privacyPolicyLink {
  return [[NSAttributedString alloc] initWithString:_LDefault(@"Privacy", @"Title of link to "
                                                              "privacy policy document")
                                         attributes:@{
    NSForegroundColorAttributeName: self.linksColor,
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.privacyPolicyURL
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

@end

NS_ASSUME_NONNULL_END
