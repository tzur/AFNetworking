// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXColorScheme.h"

SpecBegin(SPXColorScheme)

__block SPXColorScheme *colorScheme;

beforeEach(^{
  auto color = [UIColor blackColor];
  colorScheme =
      [[SPXColorScheme alloc] initWithMainColor:color textColor:color darkTextColor:color
                                grayedTextColor:color backgroundColor:color];
});

it(@"should raise if the number of main gradient colors is smaller than 2", ^{
  expect(^{
    colorScheme.mainGradientColors = @[[UIColor blackColor]];
  }).to.raise(NSInvalidArgumentException);
});

it(@"should raise if the number of multi app gradient colors is smaller than 2", ^{
  expect(^{
    colorScheme.multiAppGradientColors = @[[UIColor blackColor]];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
