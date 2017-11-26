// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionTermsView ()

/// Text view holding the terms text, terms of use link and privacy policy link.
@property (readonly, nonatomic) UITextView *termsTextView;

@end

@implementation SPXSubscriptionTermsView

- (instancetype)initWithTermsText:(NSAttributedString *)termsText
                   termsOfUseLink:(NSAttributedString *)termsOfUseLink
                privacyPolicyLink:(NSAttributedString *)privacyPolicyLink {
  if (self = [super initWithFrame:CGRectZero]) {
    [self setup];
    self.termsTextView.attributedText = [self termsTextWithTermsText:termsText
                                                      termsOfUseLink:termsOfUseLink
                                                   privacyPolicyLink:privacyPolicyLink];
  }
  return self;
}

- (NSAttributedString *)termsTextWithTermsText:(NSAttributedString *)termsText
                                termsOfUseLink:(NSAttributedString *)termsOfUseLink
                             privacyPolicyLink:(NSAttributedString *)privacyPolicyLink {
  auto terms = [[NSMutableAttributedString alloc] initWithAttributedString:termsText];
  [terms appendAttributedString:termsOfUseLink];

  NSDictionary<NSAttributedStringKey, id> *termsOverviewAttributes =
      [termsText attributesAtIndex:0 longestEffectiveRange:nil
                           inRange:NSMakeRange(0, termsText.length)];
  auto seperator = [[NSAttributedString alloc] initWithString:@" | "
                                                   attributes:termsOverviewAttributes];
  [terms appendAttributedString:seperator];

  self.termsTextView.linkTextAttributes =
      [termsOfUseLink attributesAtIndex:0 longestEffectiveRange:nil
                                inRange:NSMakeRange(0, termsOfUseLink.length)];
  [terms appendAttributedString:privacyPolicyLink];

  return terms;
}

- (void)setup {
  _termsTextView = [[UITextView alloc] init];
  self.termsTextView.editable = NO;
  self.termsTextView.scrollEnabled = NO;
  self.termsTextView.backgroundColor = [UIColor clearColor];

  [self addSubview:self.termsTextView];
  [self.termsTextView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.edges.equalTo(self);
  }];
}

@end

NS_ASSUME_NONNULL_END
