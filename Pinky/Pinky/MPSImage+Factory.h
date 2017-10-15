// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSImage objects.
@interface MPSImage (Factory)

/// Returns an \c MPSImage with a descriptor built from the \c format, \c width, \c height and
/// \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSImage *)pnk_imageWithDevice:(id<MTLDevice>)device
                           format:(MPSImageFeatureChannelFormat)format
                            width:(NSUInteger)width height:(NSUInteger)height
                         channels:(NSUInteger)channels;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatUnorm8
/// pixel format and with the \c width, \c height and \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSImage *)pnk_unorm8ImageWithDevice:(id<MTLDevice>)device
                                  width:(NSUInteger)width height:(NSUInteger)height
                               channels:(NSUInteger)channels;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatFloat16
/// pixel format and with the \c width, \c height and \c channels parameters.
///
/// @note This is a memory intensive operation and requires allocating a new texture.
+ (MPSImage *)pnk_float16ImageWithDevice:(id<MTLDevice>)device
                                   width:(NSUInteger)width height:(NSUInteger)height
                                channels:(NSUInteger)channels;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
