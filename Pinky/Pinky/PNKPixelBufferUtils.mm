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
static const std::unordered_map<OSType, std::pair<MTLPixelFormat, NSUInteger>>
    kSupportedCVPixelFormatToMTLPixelFormat = {
  {kCVPixelFormatType_OneComponent8, {MTLPixelFormatR8Unorm, 1}},
  {kCVPixelFormatType_TwoComponent8, {MTLPixelFormatRG8Unorm, 2}},
  {kCVPixelFormatType_32BGRA, {MTLPixelFormatRGBA8Unorm, 4}},
  {kCVPixelFormatType_OneComponent16Half, {MTLPixelFormatR16Float, 1}},
  {kCVPixelFormatType_TwoComponent16Half, {MTLPixelFormatRG16Float, 2}},
  {kCVPixelFormatType_64RGBAHalf, {MTLPixelFormatRGBA16Float, 4}}
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
                    @"Pixel format (%u) is not supported", (unsigned int)inputFormat);
}

void PNKAssertPixelBufferFormatChannelCount(CVPixelBufferRef pixelBuffer, NSUInteger channelCount) {
  OSType inputFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(inputFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Pixel format (%u) is not supported", (unsigned int)inputFormat);
  LTParameterAssert(pixelFormatPair->second.second == channelCount,
                    @"Pixel format is expected to have %lu channels; got %lu",
                    (unsigned long)channelCount, (unsigned long)pixelFormatPair->second.second);
}

MPSImage *PNKImageFromPixelBuffer(CVPixelBufferRef pixelBuffer, id<MTLDevice> device,
                                  NSUInteger featureChannels) {
  size_t width = CVPixelBufferGetWidth(pixelBuffer);
  size_t height = CVPixelBufferGetHeight(pixelBuffer);
  OSType inputFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(inputFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Input pixel format (%u) is not supported", (unsigned int)inputFormat);
  auto metalPixelFormat = pixelFormatPair->second.first;

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

  if (featureChannels == 0) {
    featureChannels = pixelFormatPair->second.second;
  }
  auto mpsImage = [[MPSImage alloc] initWithTexture:metalTexture featureChannels:featureChannels];
  return mpsImage;
}

#endif

NS_ASSUME_NONNULL_END
