// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKAvailability.h"

DeviceSpecBegin(PNKAvailability)

it(@"should return YES", ^{
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  auto result = PNKSupportsMTLDevice(device);
  expect(result).to.beTruthy();
});

DeviceSpecEnd
