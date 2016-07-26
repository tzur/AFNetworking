// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "CATransaction+Animations.h"

SpecBegin(CATransaction_Animations)

it(@"should perform without animation", ^{
  __block BOOL executed = NO;

  [CATransaction performWithoutAnimation:^{
    executed = YES;
    expect([CATransaction disableActions]).to.beTruthy();
  }];

  expect(executed).to.beTruthy();
});

SpecEnd
