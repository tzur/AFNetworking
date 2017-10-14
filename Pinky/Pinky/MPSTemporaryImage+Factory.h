// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSImage objects.
@interface MPSTemporaryImage (Factory)

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a descriptor built from the
/// \c format, \c width, \c height and \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSTemporaryImage *)pnk_imageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                           format:(MPSImageFeatureChannelFormat)format
                                            width:(NSUInteger)width height:(NSUInteger)height
                                         channels:(NSUInteger)channels;

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a
/// \c MPSImageFeatureChannelFormatUnorm8 pixel format and with the \c width, \c height and
/// \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSTemporaryImage *)pnk_unorm8ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                  width:(NSUInteger)width height:(NSUInteger)height
                                               channels:(NSUInteger)channels;

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a
/// \c MPSImageFeatureChannelFormatFloat16 pixel format and with the \c width, \c height and
/// \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSTemporaryImage *)pnk_float16ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                   width:(NSUInteger)width height:(NSUInteger)height
                                                channels:(NSUInteger)channels;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
