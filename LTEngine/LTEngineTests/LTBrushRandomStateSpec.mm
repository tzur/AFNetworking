// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTKit/LTRandom.h>

#import "LTBrush.h"
#import "LTBrushColorDynamicsEffect.h"
#import "LTBrushScatterEffect.h"
#import "LTBrushShapeDynamicsEffect.h"
#import "LTBrushRandomState.h"

LTSpecBegin(LTBrushRandomState)

__block LTBrushRandomState *randomState;
__block id niceBrushRandomStateMock;
__block id niceColorDynamicsEffectRandomStateMock;
__block id niceScatterDynamicsEffectRandomStateMock;
__block id niceShapeDynamicsEffectRandomStateMock;
__block NSDictionary *states;

beforeEach(^{
  niceBrushRandomStateMock = OCMClassMock([LTRandomState class]);
  niceColorDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  niceScatterDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  niceShapeDynamicsEffectRandomStateMock = OCMClassMock([LTRandomState class]);
  states = @{
    @instanceKeypath(LTBrush, random): niceBrushRandomStateMock,
    @instanceKeypath(LTBrush, colorDynamicsEffect.random):
       niceColorDynamicsEffectRandomStateMock,
    @instanceKeypath(LTBrush, scatterEffect.random):
       niceScatterDynamicsEffectRandomStateMock,
    @instanceKeypath(LTBrush, shapeDynamicsEffect.random):
       niceShapeDynamicsEffectRandomStateMock,
  };
});

context(@"deserialization", ^{
  __block NSError *error;

  beforeEach(^{
    NSDictionary *dictionary = @{@instanceKeypath(LTBrushRandomState, states): states};
    randomState = [LTBrushRandomState modelWithDictionary:dictionary error:&error];
  });

  it(@"it should deserialize without an error", ^{
    expect(randomState).toNot.beNil();
    expect(error).to.beNil();
  });

  it(@"it should deserialize correctly", ^{
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

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    randomState = [[LTBrushRandomState alloc] initWithStates:states];
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
