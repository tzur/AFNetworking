// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionTermsViewModel ()

/// Non-attributed version of the terms overview as provided on initialization.
@property (strong, nonatomic) NSString *termsOverview;

/// URL to the full terms-of-use document.
@property (strong, nonatomic) NSURL *fullTermsURL;

/// URL to the full privacy-policy document.
@property (strong, nonatomic) NSURL *privacyPolicyURL;

@end

@implementation SPXSubscriptionTermsViewModel

- (instancetype)initWithFullTerms:(NSURL *)fullTermsURL privacyPolicy:(NSURL *)privacyPolicyURL {
  auto termsString = @"Payment will be charged to your iTunes account at confirmation of purchase. "
      "Subscriptions will automatically renew unless auto-renew is turned off at least 24 hours "
      "before the end of the current period. Your account will be charged for renewal, in "
      "accordance with your plan, within 24 hours prior to the end of the current period. You can "
      "manage or turn off auto-renew in your Apple ID account settings any time after purchase. ";
  return [self initWithTermsOverview:termsString fullTerms:fullTermsURL
                       privacyPolicy:privacyPolicyURL];
}

- (instancetype)initWithTermsOverview:(NSString *)termsOverview fullTerms:(NSURL *)fullTermsURL
                        privacyPolicy:(NSURL *)privacyPolicyURL {
  if (self = [super init]) {
    _termsOverview = [termsOverview copy];
    _fullTermsURL = fullTermsURL;
    _privacyPolicyURL = privacyPolicyURL;
  }
  return self;
}

#pragma mark -
#pragma mark SPXSubscriptionTermsViewModel
#pragma mark -

- (NSAttributedString *)termsText {
  auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.alignment = NSTextAlignmentCenter;
  return [[NSMutableAttributedString alloc] initWithString:self.termsOverview attributes:@{
    NSForegroundColorAttributeName: [UIColor whiteColor],
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightLight],
    NSParagraphStyleAttributeName: paragraphStyle
  }];
}

- (NSAttributedString *)termsOfUseLink {
    return [[NSAttributedString alloc] initWithString:@"Terms of Use" attributes:@{
    NSForegroundColorAttributeName: [UIColor whiteColor],
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.fullTermsURL ?: [NSURL URLWithString:@""],
  }];
}

- (NSAttributedString *)privacyPolicyLink {
  return [[NSAttributedString alloc] initWithString:@"Privacy" attributes:@{
    NSForegroundColorAttributeName: [UIColor whiteColor],
    NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    NSLinkAttributeName: self.privacyPolicyURL ?: [NSURL URLWithString:@""]
  }];
}

@end

NS_ASSUME_NONNULL_END
