// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "LTMTLDefaults.h"

DeviceSpecBegin(LTMTLDefaults)

it(@"should return a valid device", ^{
  auto device = LTMTLDefaultDevice();
  expect(device).toNot.beNil();
});

it(@"should return a valid command queue", ^{
  auto commandQueue = LTMTLDefaultCommandQueue();
  expect(commandQueue).toNot.beNil();
});

DeviceSpecEnd
