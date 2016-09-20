// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "UIDevice+CameraMake.h"

#import <LTKit/UIDevice+Hardware.h>

SpecBegin(UIDevice_CameraMake)

__block UIDevice *device;

beforeEach(^{
  device = [[UIDevice alloc] init];
});

it(@"should return camera make", ^{
  expect(device.cam_cameraMake).to.equal(@"Apple");
});

SpecEnd
