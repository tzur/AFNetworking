// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRuntime.h"

SpecBegin(LTRuntime)

context(@"LTIsRunningTests", ^{
  it(@"should return YES when tests are running", ^{
    // This seems like an obvious test, but it will break in case Xcode changes its undocumented
    // environment variables.
    expect(LTIsRunningTests()).to.beTruthy();
  });
});

SpecEnd
