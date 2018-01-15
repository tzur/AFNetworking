// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKPixelBufferUtils.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>

#import "LTRef+Pinky.h"
#import "PNKOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Supported CVPixelFormat types for input images and their corresponding Metal pixel types for
/// mapping of the \c CVPixelBuffer to a \c MTLTexture.
static const std::unordered_map<OSType, MTLPixelFormat> kSupportedCVPixelFormatToMTLPixelFormat{
  {kCVPixelFormatType_OneComponent8, MTLPixelFormatR8Unorm},
  {kCVPixelFormatType_32BGRA, MTLPixelFormatRGBA8Unorm},
  {kCVPixelFormatType_OneComponent16Half, MTLPixelFormatR16Float},
  {kCVPixelFormatType_64RGBAHalf, MTLPixelFormatRGBA16Float}
};

static CVMetalTextureCacheRef PNKMetalTextureCacheForDevice(id<MTLDevice> device) {
  static auto mapTable =
      [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                            valueOptions:NSMapTableStrongMemory];
  static auto lock = [[NSLock alloc] init];
  [lock lock];

  CVMetalTextureCacheRef _Nullable textureCache =
     (__bridge CVMetalTextureCacheRef)[mapTable objectForKey:device];
  if (textureCache) {
    [lock unlock];
    return textureCache;
  }

  auto cacheAttributes = @{
    (__bridge_transfer NSString *)kCVMetalTextureCacheMaximumTextureAgeKey: @0
  };
  CVReturn status = CVMetalTextureCacheCreate(NULL, (__bridge CFDictionaryRef)cacheAttributes,
                                              device, NULL, &textureCache);
  LTAssert(status == kCVReturnSuccess, @"Failed creating metal texture cache - error code %d",
           status);

  [mapTable setObject:(__bridge_transfer id)textureCache forKey:device];
  [lock unlock];
  return textureCache;
}

void PNKAssertPixelBufferFormat(CVPixelBufferRef pixelBuffer) {
  OSType inputFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(inputFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Input pixel format (%u) is not supported", (unsigned int)inputFormat);
}

id<MTLTexture> PNKTextureFromPixelBuffer(CVPixelBufferRef pixelBuffer, id<MTLDevice> device) {
  size_t width = CVPixelBufferGetWidth(pixelBuffer);
  size_t height = CVPixelBufferGetHeight(pixelBuffer);
  OSType inputFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(inputFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Input pixel format (%u) is not supported", (unsigned int)inputFormat);
  auto metalPixelFormat = pixelFormatPair->second;

  CVMetalTextureCacheRef textureCache = PNKMetalTextureCacheForDevice(device);

  CVMetalTextureRef texture = NULL;
  CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL,
                                                              metalPixelFormat, width, height, 0,
                                                              &texture);
  LTAssert(status == kCVReturnSuccess, @"Failed creating Metal texture from pixel buffer %@ - "
           "error code %d", pixelBuffer, status);

  id<MTLTexture> metalTexture = CVMetalTextureGetTexture(texture);
  CVBufferRelease(texture);
  CVMetalTextureCacheFlush(textureCache, 0);
  return metalTexture;
}

#endif

NS_ASSUME_NONNULL_END
