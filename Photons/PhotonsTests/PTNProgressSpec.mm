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

context(@"map", ^{
  it(@"should return object with the same progress value if result is nil", ^{
    PTNProgress<NSString *> *progress = [[PTNProgress alloc] initWithProgress:@0.5];
    PTNProgress *mappedProgress = [progress map:^NSString *(NSString *object) {
      return object;
    }];

    expect(mappedProgress.progress).to.equal(@0.5);
    expect(mappedProgress.result).to.beNil();
  });

  it(@"should return object with result of block if result is not nil", ^{
    PTNProgress<NSString *> *progress = [PTNProgress progressWithResult:@"A"];
    PTNProgress *mappedProgress = [progress map:^NSString *(NSString *string) {
      return [string stringByAppendingString:@"B"];
    }];

    expect(mappedProgress.progress).to.beNil();
    expect(mappedProgress.result).to.equal(@"AB");
  });
});

SpecEnd
