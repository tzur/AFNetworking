// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBLibraryLoader.h"

#import <LTKitTestUtils/NSBundle+Test.h>

DeviceSpecBegin(MTBLibraryLoader)

it(@"should return a valid library containing the fillWithZeros function", ^{
  auto device = MTLCreateSystemDefaultDevice();
  NSBundle *bundle = [NSBundle lt_testBundle];
  auto path = [bundle pathForResource:@"default" ofType:@"metallib"];

  auto library = MTBLoadLibrary(device, path);

  expect([library.functionNames containsObject:@"fillWithZeros"]).to.beTruthy();
});

DeviceSpecEnd
