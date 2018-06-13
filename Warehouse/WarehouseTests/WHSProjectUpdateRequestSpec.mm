// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

#import "WHSProjectUpdateRequest.h"

SpecBegin(WHSProjectUpdateRequest)

context(@"requestForUndo", ^{
  it(@"should return undo request if step cursor is non zero", ^{
    auto project = [WHSProjectSnapshot dummyProject];
    auto request = [WHSProjectUpdateRequest requestForUndo:project];

    expect(request.stepCursor).to.equal(project.stepCursor - 1);
    expect(request.stepIDsToDelete).to.haveCountOf(0);
    expect(request.stepsContentToAdd).to.haveCountOf(0);
    expect(request.userData).to.beNil();
    expect(request.projectIdentifier).to.equal(project.identifier);
  });

  it(@"should return nil if step cursor is zero", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithZeroStepCursor];

    expect([WHSProjectUpdateRequest requestForUndo:project]).to.beNil();
  });
});

context(@"requestForRedo", ^{
  it(@"should return redo request if there are steps after step cursor", ^{
    auto project = [WHSProjectSnapshot dummyProject];
    auto request = [WHSProjectUpdateRequest requestForRedo:project];

    expect(request.stepCursor).to.equal(project.stepCursor + 1);
    expect(request.stepIDsToDelete).to.haveCountOf(0);
    expect(request.stepsContentToAdd).to.haveCountOf(0);
    expect(request.userData).to.beNil();
    expect(request.projectIdentifier).to.equal(project.identifier);
  });

  it(@"should return nil if there are no steps after step cursor", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNoStepsAfterCursor];

    expect([WHSProjectUpdateRequest requestForRedo:project]).to.beNil();
  });

  it(@"should return nil if steps are not available", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNilStepsArray];

    expect([WHSProjectUpdateRequest requestForRedo:project]).to.beNil();
  });
});

context(@"requestForAddStep", ^{
  __block WHSStepContent *stepContent;

  beforeEach(^{
    stepContent = [[WHSStepContent alloc] init];
    stepContent.userData = @{@"myNumber": @42, @"myString": @"boing"};
    stepContent.assetsSourceURL = [NSBundle mainBundle].bundleURL;
  });

  it(@"should return add request that with steps to delete if there are steps after cursor", ^{
    auto project = [WHSProjectSnapshot dummyProject];
    auto request = [WHSProjectUpdateRequest requestForAddStep:project stepContent:stepContent];

    expect(request.stepCursor).to.equal(project.stepCursor + 1);
    expect(request.stepIDsToDelete).to.equal(project.stepsAfterCursor);
    expect(request.stepsContentToAdd).to.equal(@[stepContent]);
    expect(request.userData).to.beNil();
    expect(request.projectIdentifier).to.equal(project.identifier);
  });

  it(@"should return add request with no steps to delete if there are no steps after cursor", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNoStepsAfterCursor];
    auto request = [WHSProjectUpdateRequest requestForAddStep:project stepContent:stepContent];

    expect(request.stepCursor).to.equal(project.stepCursor + 1);
    expect(request.stepIDsToDelete).to.haveCountOf(0);
    expect(request.stepsContentToAdd).to.equal(@[stepContent]);
    expect(request.userData).to.beNil();
    expect(request.projectIdentifier).to.equal(project.identifier);
  });

  it(@"should return nil if steps are not available", ^{
    auto project = [WHSProjectSnapshot dummyProjectWithNilStepsArray];

    expect([WHSProjectUpdateRequest requestForAddStep:project stepContent:stepContent]).to.beNil();
  });
});

SpecEnd
