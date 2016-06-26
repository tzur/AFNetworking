// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRCompare.h"

SpecBegin(FBRCompare)

context(@"comparison", ^{
  it(@"should indicate that an object is equal to itself", ^{
    NSObject *object = [[NSObject alloc] init];
    expect(FBRCompare(object, object)).to.beTruthy();
  });

  it(@"should indicate that two objects are equal if they are both nil", ^{
    expect(FBRCompare(nil, nil)).to.beTruthy();
  });

  it(@"should indicate that two non-identical but equivalent objects are equal", ^{
    expect(FBRCompare(@[], @[])).to.beTruthy();
  });

  it(@"should indicate that two non-identical non-equivalent objects are not equal", ^{
    expect(FBRCompare(@5, @7)).to.beFalsy();
  });
});

SpecEnd
