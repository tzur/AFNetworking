// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNProgress.h"

SpecBegin(PTNProgress)

it(@"should initialize with progress", ^{
  PTNProgress *progress = [[PTNProgress alloc] initWithProgress:@0.5];
  expect(progress.progress).to.equal(@0.5);
  expect(progress.result).to.beNil();
});

it(@"should initialize with result", ^{
  PTNProgress *progress = [[PTNProgress alloc] initWithResult:@"foo"];
  expect(progress.progress).to.beNil();
  expect(progress.result).to.equal(@"foo");
});

SpecEnd
