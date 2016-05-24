// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "CUISharedTheme.h"

SpecBegin(CUISharedTheme)

it(@"should return the bound theme", ^{
  id themeMock = OCMProtocolMock(@protocol(CUITheme));
  LTBindObjectToProtocol(themeMock, @protocol(CUITheme));
  expect([CUISharedTheme sharedTheme]).to.beIdenticalTo(themeMock);
});

it(@"should raise an exception if no bound theme", ^{
  expect(^{
    [CUISharedTheme sharedTheme];
  }).to.raiseAny();
});

SpecEnd
