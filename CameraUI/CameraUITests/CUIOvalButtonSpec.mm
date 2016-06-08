// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUIOvalButton.h"

SpecBegin(CUIOvalButton)

static const CGFloat kDisabledAlpha = 0.75;
static const CGFloat kDisabledAlpha2 = 0.25;

__block CUIOvalButton *ovalButton;

beforeEach(^{
  ovalButton = [[CUIOvalButton alloc] initWithFrame:CGRectZero];
  ovalButton.disabledAlpha = kDisabledAlpha;
});

it(@"should use disabled alpha", ^{
  expect(ovalButton.alpha).to.equal(1);
  ovalButton.enabled = NO;
  expect(ovalButton.alpha).to.equal(kDisabledAlpha);
  ovalButton.enabled = YES;
  expect(ovalButton.alpha).to.equal(1);
});

it(@"should not change alpha while enabled", ^{
  expect(ovalButton.alpha).to.equal(1);
  ovalButton.disabledAlpha = kDisabledAlpha2;
  expect(ovalButton.alpha).to.equal(1);
});

it(@"should change alpha while disabled", ^{
  ovalButton.enabled = NO;
  expect(ovalButton.alpha).to.equal(kDisabledAlpha);
  ovalButton.disabledAlpha = kDisabledAlpha2;
  expect(ovalButton.alpha).to.equal(kDisabledAlpha2);
});

SpecEnd
