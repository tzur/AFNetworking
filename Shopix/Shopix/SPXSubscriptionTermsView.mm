// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPXSubscriptionTermsView ()

/// Text view holding the terms gist text.
@property (readonly, nonatomic) UITextView *termsGistTextView;

/// Text view holding the terms text, terms of use link and privacy policy link.
@property (readonly, nonatomic) UITextView *termsTextView;

@end

@implementation SPXSubscriptionTermsView

#pragma mark -
#pragma mark Initialization
#pragma mark -

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

- (void)setup {
  [self setupTermsGistTextView];
  [self setupTermsTextView];
  [self setContentCompressionResistancePriority:UILayoutPriorityRequired
                                        forAxis:UILayoutConstraintAxisVertical];
}

- (void)setupTermsGistTextView {
  _termsGistTextView = [[UITextView alloc] init];
  self.termsGistTextView.selectable = NO;
  self.termsGistTextView.scrollEnabled = NO;
  self.termsGistTextView.textContainerInset = UIEdgeInsetsZero;
  self.termsGistTextView.backgroundColor = [UIColor clearColor];

  [self addSubview:self.termsGistTextView];
  [self updateTermsGistTextViewConstraints];
}

- (void)updateTermsGistTextViewConstraints {
  [self.termsGistTextView mas_remakeConstraints:^(MASConstraintMaker *make) {
    make.top.width.centerX.equalTo(self);
    if (!self.termsGistText) {
      make.height.equalTo(@0);
    }
  }];
}

- (void)setupTermsTextView {
  _termsTextView = [[UITextView alloc] init];
  self.termsTextView.editable = NO;
  self.termsTextView.scrollEnabled = NO;
  self.termsTextView.textContainerInset = UIEdgeInsetsZero;
  self.termsTextView.backgroundColor = [UIColor clearColor];

  [self addSubview:self.termsTextView];
  [self.termsTextView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.termsGistTextView.mas_bottom);
    make.width.centerX.equalTo(self);
  }];
}

- (NSAttributedString *)termsTextWithTermsText:(NSAttributedString *)termsText
                                termsOfUseLink:(NSAttributedString *)termsOfUseLink
                             privacyPolicyLink:(NSAttributedString *)privacyPolicyLink {
  auto terms = [[NSMutableAttributedString alloc] initWithAttributedString:termsText];
  [terms appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
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

#pragma mark -
#pragma mark Layout
#pragma mark -

- (void)layoutSubviews {
  [super layoutSubviews];
  [self invalidateIntrinsicContentSize];
}

- (CGSize)intrinsicContentSize {
  auto contentHeight =
      self.termsTextView.frame.size.height + self.termsGistTextView.frame.size.height;
  return CGSizeMake(UIViewNoIntrinsicMetric, contentHeight);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (void)setTermsTextContainerInset:(UIEdgeInsets)termsTextContainerInset {
  self.termsTextView.textContainerInset = termsTextContainerInset;
}

- (UIEdgeInsets)termsTextContainerInset {
  return self.termsTextView.textContainerInset;
}

- (void)setTermsGistText:(nullable NSAttributedString *)termsGistText {
  _termsGistText = termsGistText;
  if (termsGistText) {
    self.termsGistTextView.attributedText = termsGistText;
  }
  [self updateTermsGistTextViewConstraints];
}

@end

NS_ASSUME_NONNULL_END
