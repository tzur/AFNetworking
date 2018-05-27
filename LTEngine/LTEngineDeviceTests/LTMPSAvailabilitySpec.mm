// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTMPSAvailability.h"

DeviceSpecBegin(LTMPSAvailability)

it(@"should return true", ^{
  auto device = MTLCreateSystemDefaultDevice();

  expect(@(LTMTLDeviceSupportsMPS(device))).to.beTruthy();
});

DeviceSpecEnd
