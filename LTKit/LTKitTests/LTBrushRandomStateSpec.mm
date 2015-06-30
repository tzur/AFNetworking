// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrush.h"
#import "LTBrushColorDynamicsEffect.h"
#import "LTBrushScatterEffect.h"
#import "LTBrushShapeDynamicsEffect.h"
#import "LTBrushRandomState.h"
#import "LTKeyPathCoding.h"
#import "LTRandom.h"

LTSpecBegin(LTBrushRandomState)

__block LTBrushRandomState *randomState;
__block id niceBrushRandomStateMock;
__block id niceColorDynamicsEffectRandomStateMock;
__block id niceScatterDynamicsEffectRandomStateMock;
__block id niceShapeDynamicsEffectRandomStateMock;

beforeEach(^{
  niceBrushRandomStateMock = OCMClassMock([LTRandomState class]);
  niceColorDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  niceScatterDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  niceShapeDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  NSDictionary *dictionary = @{
    @instanceKeypath(LTBrush, random): niceBrushRandomStateMock,
    @instanceKeypath(LTBrush, colorDynamicsEffect.random):
       niceColorDynamicsEffectRandomStateMock,
    @instanceKeypath(LTBrush, scatterEffect.random):
       niceScatterDynamicsEffectRandomStateMock,
    @instanceKeypath(LTBrush, shapeDynamicsEffect.random):
       niceShapeDynamicsEffectRandomStateMock,
  };
  dictionary = @{@instanceKeypath(LTBrushRandomState, states): dictionary};
  randomState = [LTBrushRandomState modelWithDictionary:dictionary error:nil];
});

context(@"initialization", ^{
  it(@"it should initialize correctly", ^{
    expect(randomState.states[@instanceKeypath(LTBrush, random)])
        .to.beIdenticalTo(niceBrushRandomStateMock);
    expect(randomState.states[@instanceKeypath(LTBrush, colorDynamicsEffect.random)])
        .to.beIdenticalTo(niceColorDynamicsEffectRandomStateMock);
    expect(randomState.states[@instanceKeypath(LTBrush, scatterEffect.random)])
        .to.beIdenticalTo(niceScatterDynamicsEffectRandomStateMock);
    expect(randomState.states[@instanceKeypath(LTBrush, shapeDynamicsEffect.random)])
        .to.beIdenticalTo(niceShapeDynamicsEffectRandomStateMock);
  });
});

LTSpecEnd
