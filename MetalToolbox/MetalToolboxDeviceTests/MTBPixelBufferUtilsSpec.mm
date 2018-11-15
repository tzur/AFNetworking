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
  __block lt::Ref<CVMetalTextureCacheRef> cache;

  beforeEach(^{
    cache = MTBCVMetalTextureCacheCreate(device);
  });

  afterEach(^{
    cache = nil;
  });

  it(@"should create an R8Unorm image from a OneComponent8 pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_OneComponent8);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(1);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatR8Unorm);
  });

  it(@"should create an RG8Unorm image from a TwoComponent8 pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_TwoComponent8);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(2);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatRG8Unorm);
  });

  it(@"should create an RGBA8Unorm image from a 32BGRA pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(4);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatRGBA8Unorm);
  });

  it(@"should create an R16Float image from a OneComponent16Half pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight,
                                              kCVPixelFormatType_OneComponent16Half);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(1);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatR16Float);
  });

  it(@"should create an RG16Float image from a TwoComponent16Half pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight,
                                              kCVPixelFormatType_TwoComponent16Half);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(2);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatRG16Float);
  });

  it(@"should create an RGBA16Float image from a 64RGBAHalf pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_64RGBAHalf);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get());
    expect(mpsImage.width).to.equal(kWidth);
    expect(mpsImage.height).to.equal(kHeight);
    expect(mpsImage.featureChannels).to.equal(4);
    expect(mpsImage.pixelFormat).to.equal(MTLPixelFormatRGBA16Float);
  });

  it(@"should create an image with number of feature channels less than number of channels of "
     "pixel buffer", ^{
    auto pixelBuffer = MTBCVPixelBufferCreate(kWidth, kHeight, kCVPixelFormatType_32BGRA);
    auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer.get(), cache.get(), 3);
    expect(mpsImage).toNot.beNil();
  });

  it(@"should fail to create an image if number of feature channels exceeds number of channels of "
     "pixel buffer", ^{
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
