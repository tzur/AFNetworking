// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "SPXColorScheme.h"

SpecBegin(SPXColorScheme)

it(@"should raise if the number of main gradient colors is smaller than 2", ^{
  auto color = [UIColor blackColor];
  auto colorScheme =
      [[SPXColorScheme alloc] initWithMainColor:color textColor:color darkTextColor:color
                                grayedTextColor:color backgroundColor:color];

  expect(^{
    colorScheme.mainGradientColors = @[color];
  }).to.raise(NSInvalidArgumentException);
});

SpecEnd
