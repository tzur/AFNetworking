// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CAMVolumeButtonsController.h"

SpecBegin(CAMVolumeButtonsController)

__block UIView *target;

beforeEach(^{
  target = [[UIView alloc] initWithFrame:CGRectZero];
});

it(@"should not retain itself before starting", ^{
  __weak CAMVolumeButtonsController *weakController;
  @autoreleasepool {
    CAMVolumeButtonsController *controller =
        [[CAMVolumeButtonsController alloc] initWithTargetView:target];
    expect(controller.started).to.beFalsy();

    weakController = controller;
    expect(weakController).notTo.beNil();
  }
  expect(weakController).to.beNil();
});

it(@"should not retain itself after starting", ^{
  __weak CAMVolumeButtonsController *weakController;
  @autoreleasepool {
    CAMVolumeButtonsController *controller =
        [[CAMVolumeButtonsController alloc] initWithTargetView:target];
    [controller start];
    expect(controller.started).to.beTruthy();

    weakController = controller;
    expect(weakController).notTo.beNil();
  }
  expect(weakController).to.beNil();
});

it(@"should not retain itself after stopping", ^{
  __weak CAMVolumeButtonsController *weakController;
  @autoreleasepool {
    CAMVolumeButtonsController *controller =
        [[CAMVolumeButtonsController alloc] initWithTargetView:target];
    [controller start];
    [controller stop];
    expect(controller.started).to.beFalsy();

    weakController = controller;
    expect(weakController).notTo.beNil();
  }
  expect(weakController).to.beNil();
});

SpecEnd
