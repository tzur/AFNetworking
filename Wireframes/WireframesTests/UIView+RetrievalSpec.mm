// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "UIView+Retrieval.h"

SpecBegin(UIView_Retrieval)

__block UIView *view;

beforeEach(^{
  view = [[UIView alloc] initWithFrame:CGRectZero];
  for (NSUInteger i = 0; i < 3; ++i) {
    UIView *subview = [[UIView alloc] initWithFrame:CGRectZero];
    for (NSUInteger j = 0; j < 3; ++j) {
      [subview addSubview:[[UIView alloc] initWithFrame:CGRectZero]];
    }
    [view addSubview:subview];
  }
});

afterEach(^{
  view = nil;
});

it(@"should return subview with the given accessibility identifier", ^{
  view.subviews[1].subviews[1].accessibilityIdentifier = @"testIdentifier";
  expect([view wf_viewForAccessibilityIdentifier:@"testIdentifier"])
      .to.beIdenticalTo(view.subviews[1].subviews[1]);
});

it(@"should return the first subview with the given accessibility identifier", ^{
  view.subviews[1].subviews[1].accessibilityIdentifier = @"testIdentifier";
  view.subviews[0].subviews[2].accessibilityIdentifier = @"testIdentifier";
  expect([view wf_viewForAccessibilityIdentifier:@"testIdentifier"])
      .to.beIdenticalTo(view.subviews[0].subviews[2]);
});

it(@"should return nil if there is no subview with the given accessibility identifier", ^{
  expect([view wf_viewForAccessibilityIdentifier:@"testIdentifier"]).to.beNil();
});

it(@"should return the receiver if it has the given accessibility identifier", ^{
  view.accessibilityIdentifier = @"testIdentifier";
  expect([view wf_viewForAccessibilityIdentifier:@"testIdentifier"]).to.beIdenticalTo(view);
});

SpecEnd
