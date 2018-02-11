// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Nofar Noy.

#import "PNKLibraryLoader.h"

DeviceSpecBegin(PNKLoadLibrary)

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

it(@"should load library", ^{
  auto library = PNKLoadLibrary(device);
  expect(library).notTo.beNil();
});

it(@"should use caching", ^{
  __block NSUInteger callingCount = 0;
  id libraryMock = OCMProtocolMock(@protocol(MTLLibrary));
  id deviceMock = OCMProtocolMock(@protocol(MTLDevice));
  OCMStub([deviceMock newLibraryWithFile:[OCMArg any] error:[OCMArg anyObjectRef]])
      .andDo(^(NSInvocation * __unused invocation) {
    callingCount++;
  }).andReturn(libraryMock);
  auto library = PNKLoadLibrary(deviceMock);
  library = PNKLoadLibrary(deviceMock);
  expect(callingCount).to.equal(1);
});

DeviceSpecEnd
