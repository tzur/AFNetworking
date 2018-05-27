// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectSnapshot.h"

SpecBegin(WHSProjectSnapshot)

context(@"canUndo", ^{
  it(@"should be YES if step cursor is non zero", ^{
    auto project = [WHSProjectSnapshot dummyProject];

    expect(project.canUndo).to.beTruthy();
  });

  it(@"should be NO if step cursor is zero", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithZeroStepCursor];

    expect(project.canUndo).to.beFalsy();
  });
});

context(@"canRedo", ^{
  it(@"should be YES if there are steps after step cursor", ^{
    auto project = [WHSProjectSnapshot dummyProject];

    expect(project.canRedo).to.beTruthy();
  });

  it(@"should be NO if no steps after step cursor", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNoStepsAfterCursor];

    expect(project.canRedo).to.beFalsy();
  });

  it(@"should be NO if steps are not available", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNilStepsIDs];

    expect(project.canRedo).to.beFalsy();
  });
});

SpecEnd
