// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#if !defined(__OBJC__) || !COREVIDEO_SUPPORTS_METAL
  typedef void *CVMetalTextureCacheRef;
#endif

NS_ASSUME_NONNULL_BEGIN

/// Creates an \c MPSImage wrapper of the \c pixelBuffer and stores the underlying Metal texture
/// in \c textureCache. The newly created \c MPSImage is returned to the caller. \c pixelBuffer must
/// be of one of the supported supported pixel formats. Currently supported pixel formats are 1-,
/// 2- and 4-channels non-planar formats with either uchar or half-float channels. The wrapper image
/// will have feature channels count equal to \c featureChannels. \c featureChannels must not exceed
/// the number of channels of the pixel buffer. If \c featureChannels is zero the number of channels
/// of the pixel buffer will be used.
///
/// @note This function does not have any synchronization mechanisms whatsoever. The synchronization
/// of reading/writing the \c pixelBuffer from the CPU side and reading/writing the \c MPSImage from
/// the GPU side should be handled by the caller.
MPSImage *MTBImageFromPixelBuffer(CVPixelBufferRef pixelBuffer, CVMetalTextureCacheRef textureCache,
                                  NSUInteger featureChannels = 0);

/// Creates an \c MPSImage wrapper of the \c pixelBuffer for use on \c device and returns it to the
/// caller. \c pixelBuffer must be backed by an \c IOSurface. \c pixelBuffer must be of one of the
/// supported supported pixel formats. Currently supported pixel formats are 1-, 2- and 4-channels
/// non-planar formats with either uchar or half-float channels. The wrapper image will have feature
/// channels count equal to \c featureChannels. \c featureChannels must not exceed the number of
/// channels of the pixel buffer. If \c featureChannels is zero the number of channels of the pixel
/// buffer will be used.
///
/// @note This function does not have any synchronization mechanisms whatsoever. The synchronization
/// of reading/writing the \c pixelBuffer from the CPU side and reading/writing the \c MPSImage from
/// the GPU side should be handled by the caller.
MPSImage *MTBImageFromPixelBuffer(CVPixelBufferRef pixelBuffer, id<MTLDevice> device,
                                  NSUInteger featureChannels = 0) API_AVAILABLE(ios(11.0));

NS_ASSUME_NONNULL_END
