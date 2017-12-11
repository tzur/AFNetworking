// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Gennadi Iosad.

#import "CUITheme.h"

SpecBegin(CUITheme)

it(@"should return the bound theme", ^{
  id themeMock = LTMockClass([CUITheme class]);
  expect([CUITheme sharedTheme]).to.beIdenticalTo(themeMock);
});

it(@"should raise an exception if no bound theme", ^{
  expect(^{
    [CUITheme sharedTheme];
  }).to.raiseAny();
});

SpecEnd
