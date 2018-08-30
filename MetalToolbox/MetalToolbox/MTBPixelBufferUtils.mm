// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "MTBPixelBufferUtils.h"

NS_ASSUME_NONNULL_BEGIN

#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  #define MTB_UNUSED __unused
#else
  #define MTB_UNUSED
#endif

namespace lt {
template <> struct IsCoreFoundationObjectRef<CVPixelBufferRef> : public std::true_type {};
} // namespace lt

namespace mtb {

struct MPSImageMetadata {
  /// Image width.
  size_t width;

  /// Image height.
  size_t height;

  /// Image pixel format.
  MTLPixelFormat pixelFormat;

  /// Feature channels count.
  NSUInteger featureChannels;
};

} // namespace mtb

/// Supported CVPixelFormat types for input images and their corresponding Metal pixel types for
/// mapping of the \c CVPixelBuffer to a \c MTLTexture.
static const std::unordered_map<OSType, std::pair<MTLPixelFormat, NSUInteger>>
    kSupportedCVPixelFormatToMTLPixelFormat = {
      {kCVPixelFormatType_OneComponent8, {MTLPixelFormatR8Unorm, 1}},
      {kCVPixelFormatType_TwoComponent8, {MTLPixelFormatRG8Unorm, 2}},
      {kCVPixelFormatType_32BGRA, {MTLPixelFormatRGBA8Unorm, 4}},
      {kCVPixelFormatType_OneComponent16Half, {MTLPixelFormatR16Float, 1}},
      {kCVPixelFormatType_TwoComponent16Half, {MTLPixelFormatRG16Unorm, 2}},
      {kCVPixelFormatType_64RGBAHalf, {MTLPixelFormatRGBA16Float, 4}}
    };

MTB_UNUSED static mtb::MPSImageMetadata MTBImageMetadata(MTB_UNUSED CVPixelBufferRef pixelBuffer,
                                                         MTB_UNUSED NSUInteger featureChannels) {
#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  LTAssert(NO, @"Core Video does not support Metal on simulator");
#else
  auto pixelBufferFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
  auto pixelFormatPair = kSupportedCVPixelFormatToMTLPixelFormat.find(pixelBufferFormat);
  LTParameterAssert(pixelFormatPair != kSupportedCVPixelFormatToMTLPixelFormat.end(),
                    @"Pixel format %lu is not supported", (unsigned long)pixelBufferFormat);
  auto metalPixelFormat = pixelFormatPair->second.first;

  if (!featureChannels) {
    featureChannels = pixelFormatPair->second.second;
  }
  LTParameterAssert(featureChannels <= pixelFormatPair->second.second, @"Cannot create an image "
                    "with %lu feature channels from a buffer with pixel format %lu",
                    (unsigned long)featureChannels, (unsigned long)pixelBufferFormat);

  return {
    .width = CVPixelBufferGetWidth(pixelBuffer),
    .height = CVPixelBufferGetHeight(pixelBuffer),
    .pixelFormat = metalPixelFormat,
    .featureChannels = featureChannels
  };
#endif
}

MPSImage *MTBImageFromPixelBuffer(MTB_UNUSED CVPixelBufferRef pixelBuffer,
                                  MTB_UNUSED CVMetalTextureCacheRef textureCache,
                                  MTB_UNUSED NSUInteger featureChannels) {
#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  LTAssert(NO, @"Core Video does not support Metal on simulator");
#else
  auto metadata = MTBImageMetadata(pixelBuffer, featureChannels);

  CVMetalTextureRef _Nullable textureRef;
  CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, pixelBuffer, NULL,
                                                              metadata.pixelFormat, metadata.width,
                                                              metadata.height, 0, &textureRef);
  LTParameterAssert(status == kCVReturnSuccess, @"Failed creating Metal texture from pixel buffer "
                    "%@ - error code %d", pixelBuffer, status);

  lt::Ref<CVMetalTextureRef> textureRefWrapper(textureRef);

  id<MTLTexture> _Nullable texture = CVMetalTextureGetTexture(textureRefWrapper.get());
  LTParameterAssert(texture, @"Failed to retrieve an MTLTexture object from CVMetalTextureRef");

  return [[MPSImage alloc] initWithTexture:nn(texture) featureChannels:metadata.featureChannels];
#endif
}

MPSImage *MTBImageFromPixelBuffer(MTB_UNUSED CVPixelBufferRef pixelBuffer,
                                  MTB_UNUSED id<MTLDevice> device,
                                  MTB_UNUSED NSUInteger featureChannels) {
#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  LTAssert(NO, @"Core Video does not support Metal on simulator");
#else
  auto metadata = MTBImageMetadata(pixelBuffer, featureChannels);

  auto _Nullable ioSurface = CVPixelBufferGetIOSurface(pixelBuffer);
  LTParameterAssert(ioSurface, @"Pixel buffer %@ is not backed by an IOSurface", pixelBuffer);

  auto textureDescriptor = [MTLTextureDescriptor
                            texture2DDescriptorWithPixelFormat:metadata.pixelFormat
                            width:metadata.width height:metadata.height mipmapped:NO];

  auto texture = [device newTextureWithDescriptor:textureDescriptor iosurface:nn(ioSurface)
                                            plane:0];
  LTParameterAssert(texture, @"Failed to crate a MTLTexture object from IOSurface %@ for use with "
                    "device %@", ioSurface, device);

  return [[MPSImage alloc] initWithTexture:nn(texture) featureChannels:metadata.featureChannels];
#endif
}

NS_ASSUME_NONNULL_END
