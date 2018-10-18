// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKPixelBufferUtils.h"

#import <LTEngine/CVPixelBuffer+LTEngine.h>
#import <MetalToolbox/MTBPixelBufferUtils.h>

#import "LTRef+Pinky.h"
#import "PNKOpenCVExtensions.h"

NS_ASSUME_NONNULL_BEGIN

#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  #define PNK_UNUSED __unused
#else
  #define PNK_UNUSED
#endif

#if defined(__OBJC__) && COREVIDEO_SUPPORTS_METAL

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

#endif

MPSImage *PNKImageFromPixelBuffer(PNK_UNUSED CVPixelBufferRef pixelBuffer,
                                  PNK_UNUSED id<MTLDevice> device,
                                  PNK_UNUSED NSUInteger featureChannels) {
#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  LTAssert(NO, @"Core Video does not support Metal on simulator");
#else
  auto textureCache = PNKMetalTextureCacheForDevice(device);
  auto mpsImage = MTBImageFromPixelBuffer(pixelBuffer, textureCache, featureChannels);
  CVMetalTextureCacheFlush(textureCache, 0);

  return mpsImage;
#endif
}

NS_ASSUME_NONNULL_END
