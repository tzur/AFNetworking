// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "TLProperties+Laboratory.h"

SpecBegin(TLProperties_Laboratory)

it(@"should respond to appName selector", ^{
  expect([TLProperties instancesRespondToSelector:@selector(appName)]).to.beTruthy();
});

it(@"should respond to dynamicVariables selector", ^{
  expect([TLProperties instancesRespondToSelector:@selector(dynamicVariables)]).to.beTruthy();
});

it(@"should respond to experiments selector", ^{
  expect([TLProperties instancesRespondToSelector:@selector(experiments)]).to.beTruthy();
});

it(@"should respond to experimentAndVariationNames selector", ^{
  expect([TLProperties instancesRespondToSelector:@selector(experimentAndVariationNames)])
      .to.beTruthy();
});

it(@"should respond to sessionID selector", ^{
  expect([TLProperties instancesRespondToSelector:@selector(sessionID)]).to.beTruthy();
});

SpecEnd
