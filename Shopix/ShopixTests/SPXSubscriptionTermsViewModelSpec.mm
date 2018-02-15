// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXSubscriptionTermsViewModel.h"

SpecBegin(SPXSubscriptionTermsViewModelSpec)

__block SPXSubscriptionTermsViewModel *termsViewModel;

beforeEach(^{
  auto url = [[NSURL alloc] initWithString:@"http://foo"];
  termsViewModel = [[SPXSubscriptionTermsViewModel alloc]
                    initWithTermsOverview:@"bar" fullTerms:url
                    privacyPolicy:url termsTextColor:[UIColor whiteColor]
                    linksColor:[UIColor blackColor]];
});

it(@"should be colored by the given terms text color", ^{
  auto termsText = termsViewModel.termsText;
  UIColor *termsColor = [termsText attribute:NSForegroundColorAttributeName atIndex:0
                         longestEffectiveRange:nil inRange:NSMakeRange(0, termsText.length)];

  expect(termsColor).to.equal([UIColor whiteColor]);
});

it(@"should be colored by the given links text color", ^{
  auto termsOfUseLink = termsViewModel.termsOfUseLink;

  UIColor *termsOfUseColor =
      [termsOfUseLink attribute:NSForegroundColorAttributeName atIndex:0
          longestEffectiveRange:nil inRange:NSMakeRange(0, termsOfUseLink.length)];

  expect(termsOfUseColor).to.equal([UIColor blackColor]);
});

SpecEnd
