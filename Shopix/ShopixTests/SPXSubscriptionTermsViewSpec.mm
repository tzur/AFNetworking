// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsView.h"

SpecBegin(SPXSubscriptionTermsViewSpec)

__block SPXSubscriptionTermsView *termsView;
__block NSAttributedString *onePointHeightText;

beforeEach(^{
  auto paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.maximumLineHeight = 1.0;
  onePointHeightText = [[NSAttributedString alloc] initWithString:@"foo" attributes:@{
    NSParagraphStyleAttributeName: paragraphStyle,
    NSFontAttributeName: [UIFont systemFontOfSize:1]
  }];
  termsView = [[SPXSubscriptionTermsView alloc] initWithTermsText:onePointHeightText
                                                   termsOfUseLink:onePointHeightText
                                                privacyPolicyLink:onePointHeightText];
  termsView.frame = CGRectMake(0, 0, 100, 100);
});

it(@"should change its intrinsic content size according to the terms height", ^{
  [termsView layoutIfNeeded];

  expect(termsView.intrinsicContentSize.height).to.equal(1);
});

it(@"should change its intrinsic content size according to the terms and terms gist height", ^{
  termsView.termsGistText = onePointHeightText;
  [termsView layoutIfNeeded];

  expect(termsView.intrinsicContentSize.height).to.equal(2);
});

it(@"should change its intrinsic content size if frame size forces breaking the text to multiple "
   "lines", ^{
  termsView.frame = CGRectMake(0, 0, 14, 100);
  [termsView layoutIfNeeded];

  expect(termsView.intrinsicContentSize.height).to.equal(3);
});

it(@"should change its intrinsic content size according to the terms insets", ^{
  termsView.termsTextContainerInset = UIEdgeInsetsMake(2, 0, 3, 0);
  [termsView layoutIfNeeded];

  expect(termsView.intrinsicContentSize.height).to.equal(6);
});

SpecEnd
