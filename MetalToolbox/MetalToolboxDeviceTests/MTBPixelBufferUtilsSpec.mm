// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBPixelBufferUtils.h"

namespace lt {

template <> struct IsCoreFoundationObjectRef<CVPixelBufferRef> : public std::true_type {};
template <> struct IsCoreFoundationObjectRef<CVMetalTextureCacheRef> : public std::true_type {};

} // namespace lt

static lt::Ref<CVPixelBufferRef> MTBCVPixelBufferCreate(size_t width, size_t height,
                                                        OSType pixelFormatType) {
  NSDictionary *attributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey: @{}};
  CVPixelBufferRef pixelBufferRef;
  CVPixelBufferCreate(NULL, width, height, pixelFormatType, (__bridge CFDictionaryRef)attributes,
                      &pixelBufferRef);
  return lt::Ref<CVPixelBufferRef>(pixelBufferRef);
}

static lt::Ref<CVMetalTextureCacheRef> MTBCVMetalTextureCacheCreate(id<MTLDevice> device) {
  CVMetalTextureCacheRef textureCache;
  auto cacheAttributes = @{
    (__bridge_transfer NSString *)kCVMetalTextureCacheMaximumTextureAgeKey: @0
  };
  CVMetalTextureCacheCreate(NULL, (__bridge CFDictionaryRef)cacheAttributes, device, NULL,
                            &textureCache);
  return lt::Ref<CVMetalTextureCacheRef>(textureCache);
}

DeviceSpecBegin(MTBPixelBufferUtils)

static const NSUInteger kWidth = 5;
static const NSUInteger kHeight = 4;

__block id<MTLDevice> device;

beforeEach(^{
  device = MTLCreateSystemDefaultDevice();
});

afterEach(^{
  device = nil;
});

context(@"MPSImage creation from texture cache", ^{
  it(@"should create an image from a pixel buffer", ^{
    auto cache = MTBCVMetalTextureCacheCreate(device);
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage).toNot.beNil();
  });

  it(@"should create an image with number of feature channels less than number of channels of "
     "pixel buffer", ^{
    auto cache = MTBCVMetalTextureCacheCreate(device);
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get(), 3);
    expect(mpsImage).toNot.beNil();
  });

  it(@"should fail to create an image if number of feature channels exceeds number of channels of "
     "pixel buffer", ^{
     auto cache = MTBCVMetalTextureCacheCreate(device);
     auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
     expect(^{
       __unused auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get(), 5);
     }).to.raise(NSInvalidArgumentException);
   });
});

if (@available(iOS 11.0, *)) {
  context(@"MPSImage creation from IOSurface", ^{
    it(@"should create an image from a pixel buffer", ^{
      auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
      auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), device);
      expect(mpsImage).toNot.beNil();
    });

    it(@"should create an image with number of feature channels is less than number of channels of "
       "pixel buffer", ^{
      auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
      auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), device, 3);
      expect(mpsImage).toNot.beNil();
    });

    it(@"should fail to create an image for device if number of feature channels exceeds number of "
       "channels of pixel buffer", ^{
      auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
      expect(^{
        __unused auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), device, 5);
      }).to.raise(NSInvalidArgumentException);
    });
  });
}

DeviceSpecEnd
