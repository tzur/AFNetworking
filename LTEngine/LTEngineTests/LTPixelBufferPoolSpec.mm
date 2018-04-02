// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "LTPixelBufferPool.h"

#import "LTGLPixelFormat.h"

SpecBegin(LTPixelBufferPool)

it(@"should create pixel buffer pool", ^{
  LTPixelBufferPool *pool = [[LTPixelBufferPool alloc]
                             initWithPixelFormat:kCVPixelFormatType_32BGRA
                             width:1 height:2 minimumBufferCount:0 maximumBufferAge:0];
  expect(pool.pixelFormat).to.equal(kCVPixelFormatType_32BGRA);
  expect(pool.width).to.equal(1);
  expect(pool.height).to.equal(2);
});

it(@"should create pixel buffer pool with preallocated buffers", ^{
  expect(^{
    LTPixelBufferPool * __unused pool = [[LTPixelBufferPool alloc]
                                         initWithPixelFormat:kCVPixelFormatType_32BGRA
                                         width:1 height:1 minimumBufferCount:2 maximumBufferAge:0];
  }).notTo.raiseAny();
});

it(@"should create pixel buffer pool with maximum buffer age", ^{
  expect(^{
    LTPixelBufferPool * __unused pool = [[LTPixelBufferPool alloc]
                                         initWithPixelFormat:kCVPixelFormatType_32BGRA
                                         width:1 height:1 minimumBufferCount:0 maximumBufferAge:1];
  }).notTo.raiseAny();
});

it(@"should raise when width or height are non-positive", ^{
  expect(^{
    LTPixelBufferPool * __unused pool = [[LTPixelBufferPool alloc]
                                         initWithPixelFormat:kCVPixelFormatType_32BGRA
                                         width:0 height:1 minimumBufferCount:0 maximumBufferAge:0];
  }).to.raiseAny();

  expect(^{
    LTPixelBufferPool * __unused pool = [[LTPixelBufferPool alloc]
                                         initWithPixelFormat:kCVPixelFormatType_32BGRA
                                         width:1 height:0 minimumBufferCount:0 maximumBufferAge:0];
  }).to.raiseAny();
});

LTGLPixelFormatSupportedCVPixelFormatTypes planarFormats =
    [LTGLPixelFormat supportedPlanarCVPixelFormatTypes];
LTGLPixelFormatSupportedCVPixelFormatTypes formats = [LTGLPixelFormat supportedCVPixelFormatTypes];
formats.insert(formats.end(), planarFormats.cbegin(), planarFormats.cend());

for (OSType pixelFormat : formats) {
  it(@"should create pool and allocate pixel buffer with correct format", ^{
    LTPixelBufferPool *pool = [[LTPixelBufferPool alloc]
                               initWithPixelFormat:pixelFormat
                               width:2 height:1 minimumBufferCount:0 maximumBufferAge:0];

    __block auto pixelBuffer = [pool createPixelBuffer];

    expect(pixelBuffer.get()).notTo.beNil();
    expect(CVPixelBufferGetWidth(pixelBuffer.get())).to.equal(2);
    expect(CVPixelBufferGetHeight(pixelBuffer.get())).to.equal(1);
    expect(CVPixelBufferGetPixelFormatType(pixelBuffer.get())).to.equal(pixelFormat);
  });
}

context(@"maximum buffers limit", ^{
  __block LTPixelBufferPool *pool;

  beforeEach(^{
    pool = [[LTPixelBufferPool alloc] initWithPixelFormat:kCVPixelFormatType_32BGRA
                                                    width:1 height:1
                                       minimumBufferCount:0
                                         maximumBufferAge:0];
  });

  afterEach(^{
    pool = nil;
  });

  it(@"should allocate pixel buffer when maximal allocated count is not exceeded", ^{
    __block auto pixelBuffer = [pool createPixelBufferNotExceedingMaximumBufferCount:1];
    expect(pixelBuffer.get()).notTo.beNil();
  });

  it(@"should return empty reference when maximal allocated count is exceeded", ^{
    __block auto pixelBuffer = [pool createPixelBufferNotExceedingMaximumBufferCount:0];
    expect(pixelBuffer.get()).to.beNil();
  });
});

SpecEnd
