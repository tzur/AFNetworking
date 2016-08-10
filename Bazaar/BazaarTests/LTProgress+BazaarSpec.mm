// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTProgress+Bazaar.h"

SpecBegin(LTProgress_Bazaar)

it(@"should return progress object with correct progress value", ^{
  LTProgress *progress = [LTProgress progressWithTotalUnitCount:@100 completedUnitCount:@50];

  expect(progress).toNot.beNil();
  expect(progress.progress).to.beCloseToWithin(0.5, DBL_EPSILON);
  expect(progress.result).to.beNil();
});

it(@"should return progress object with progress value set to 0 if no work has completed", ^{
  LTProgress *progress = [LTProgress progressWithTotalUnitCount:@100 completedUnitCount:@0];

  expect(progress).toNot.beNil();
  expect(progress.progress).to.equal(0);
  expect(progress.result).to.beNil();
});

it(@"should return progress object with progress value set to 0 if no work to be done", ^{
  LTProgress *progress = [LTProgress progressWithTotalUnitCount:@0 completedUnitCount:@50];

  expect(progress).toNot.beNil();
  expect(progress.progress).to.equal(0);
  expect(progress.result).to.beNil();
});

it(@"should return progress object with progress value set to 1 if all work has completed", ^{
  LTProgress *progress = [LTProgress progressWithTotalUnitCount:@100 completedUnitCount:@100];

  expect(progress).toNot.beNil();
  expect(progress.progress).to.equal(1);
  expect(progress.result).to.beNil();
});

it(@"should raise exception if total units count is negative", ^{
  expect(^{
    LTProgress __unused *progres = [LTProgress progressWithTotalUnitCount:@(-1)
                                                       completedUnitCount:@1];
  }).raise(NSInvalidArgumentException);
});

it(@"should raise exception if completed units count is negative", ^{
  expect(^{
    LTProgress __unused *progres = [LTProgress progressWithTotalUnitCount:@1
                                                       completedUnitCount:@(-1)];
  }).raise(NSInvalidArgumentException);
});

SpecEnd
