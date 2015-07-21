// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrush.h"
#import "LTBrushRandomState.h"
#import "LTBrushRandomState+LTBrush.h"
#import "LTRandom.h"

LTSpecBegin(LTBrushRandomState_LTBrush)

context(@"factory methods", ^{
  it(@"should return an instance with the correct seed", ^{
    NSUInteger seed = 0;
    LTBrush *brush = [[LTBrush alloc] init];
    LTBrushRandomState *randomState = [LTBrushRandomState randomStateWithSeed:seed forBrush:brush];
    expect(randomState).toNot.beNil();
    LTRandomState *expectedState = [[LTRandom alloc] initWithSeed:seed].engineState;
    [randomState.states enumerateKeysAndObjectsUsingBlock:^(id, id object, BOOL *) {
      expect(object).to.equal(expectedState);
    }];
    expect([NSSet setWithArray:[randomState.states allKeys]])
        .to.equal([NSSet setWithArray:[brush.randomState.states allKeys]]);

    seed = 10;
    randomState = [LTBrushRandomState randomStateWithSeed:seed forBrush:brush];
    expect(randomState).toNot.beNil();
    expectedState = [[LTRandom alloc] initWithSeed:seed].engineState;
    [randomState.states enumerateKeysAndObjectsUsingBlock:^(id, id object, BOOL *) {
      expect(object).to.equal(expectedState);
    }];
    expect([NSSet setWithArray:[randomState.states allKeys]])
        .to.equal([NSSet setWithArray:[brush.randomState.states allKeys]]);
  });
});

LTSpecEnd
