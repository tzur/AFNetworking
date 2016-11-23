// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Alex Gershovich.

#import "LTPixelBufferPool.h"

#import <CoreVideo/CVPixelBufferPool.h>
#import <LTKit/LTRef.h>

#import "LTGLPixelFormat.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTPixelBufferPool () {
  /// Reference to the pixel buffer pool managed by this instance.
  lt::Ref<CVPixelBufferPoolRef> _pixelBufferPool;
}

@end

@implementation LTPixelBufferPool

- (instancetype)initWithPixelFormat:(OSType)pixelFormat
                              width:(size_t)width
                             height:(size_t)height
                 minimumBufferCount:(size_t)minimumBufferCount
                   maximumBufferAge:(CFAbsoluteTime)maximumBufferAge {
  LTParameterAssert(width > 0);
  LTParameterAssert(height > 0);

  if (self = [super init]) {
    _pixelFormat = pixelFormat;
    _width = width;
    _height = height;
    _pixelBufferPool = [self.class createPixelBufferPoolWithPixelFormat:pixelFormat
                                                                  width:width
                                                                 height:height
                                                     minimumBufferCount:minimumBufferCount
                                                       maximumBufferAge:maximumBufferAge];
  }
  return self;
}

+ (lt::Ref<CVPixelBufferPoolRef>)
    createPixelBufferPoolWithPixelFormat:(OSType)pixelFormat
                                   width:(size_t)width
                                  height:(size_t)height
                      minimumBufferCount:(size_t)minimumBufferCount
                        maximumBufferAge:(CFAbsoluteTime)maximumBufferAge {
  NSDictionary *poolAttributes = @{
    (NSString *)kCVPixelBufferPoolMinimumBufferCountKey: @(minimumBufferCount),
    (NSString *)kCVPixelBufferPoolMaximumBufferAgeKey: @(maximumBufferAge)
  };

  NSDictionary *pixelBufferAttributes = @{
    (NSString *)kCVPixelBufferPixelFormatTypeKey: @(pixelFormat),
    (NSString *)kCVPixelBufferWidthKey: @(width),
    (NSString *)kCVPixelBufferHeightKey: @(height),
    (NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}
  };

  CVPixelBufferPoolRef pixelBufferPool;
  CVReturn ret = CVPixelBufferPoolCreate(NULL,
                                         (__bridge CFDictionaryRef)poolAttributes,
                                         (__bridge CFDictionaryRef)pixelBufferAttributes,
                                         &pixelBufferPool);
  LTAssert(ret == kCVReturnSuccess, @"Failed creating a pixel buffer pool: %d", ret);

  return lt::Ref<CVPixelBufferPoolRef>{pixelBufferPool};
}

- (lt::Ref<CVPixelBufferRef>)createPixelBuffer {
  CVPixelBufferRef pixelBuffer;
  CVReturn ret = CVPixelBufferPoolCreatePixelBuffer(NULL, _pixelBufferPool.get(), &pixelBuffer);
  LTAssert(ret == kCVReturnSuccess, @"Failed creating a pixel buffer: %d", ret);
  return lt::Ref<CVPixelBufferRef>{pixelBuffer};
}

- (lt::Ref<CVPixelBufferRef>)createPixelBufferNotExceedingMaximumBufferCount:(size_t)count {
  CFDictionaryRef auxAttributes = (__bridge CFDictionaryRef)@{
    (NSString *)kCVPixelBufferPoolAllocationThresholdKey: @(count)
  };

  CVPixelBufferRef pixelBuffer;
  CVReturn ret = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(NULL, _pixelBufferPool.get(),
                                                                     auxAttributes, &pixelBuffer);
  if (ret == kCVReturnWouldExceedAllocationThreshold) {
    return lt::Ref<CVPixelBufferRef>();
  }

  LTAssert(ret == kCVReturnSuccess, @"Failed creating a pixel buffer: %d", ret);

  return lt::Ref<CVPixelBufferRef>{pixelBuffer};
}

- (void)flush {
  CVPixelBufferPoolFlush(_pixelBufferPool.get(), kCVPixelBufferPoolFlushExcessBuffers);
}

- (void)flushAged {
  CVPixelBufferPoolFlush(_pixelBufferPool.get(), 0);
}

@end

NS_ASSUME_NONNULL_END
