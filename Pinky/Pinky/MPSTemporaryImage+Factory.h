// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

#if PNK_USE_MPS

/// Category for conveniently creating \c MPSImage objects.
@interface MPSTemporaryImage (Factory)

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a descriptor built from the
/// \c format, \c width, \c height and \c channels parameters.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_imageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                           format:(MPSImageFeatureChannelFormat)format
                                            width:(NSUInteger)width height:(NSUInteger)height
                                         channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage allocated for usage on \c buffer with a descriptor built from
/// the \c format and \c size parameters. The depth property of \c size is interpreted to be the
/// number of channels, not to be confused with the number of textures in an array type image.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_imageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                           format:(MPSImageFeatureChannelFormat)format
                                             size:(MTLSize)size;

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a
/// \c MPSImageFeatureChannelFormatUnorm8 pixel format and with the \c width, \c height and
/// \c channels parameters.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_unorm8ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                  width:(NSUInteger)width height:(NSUInteger)height
                                               channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage allocated for usage on \c buffer with a descriptor built with a
/// \c MPSImageFeatureChannelFormatUnorm8 pixel format and \c size. The depth property of \c size is
/// interpreted to be the number of channels, not to be confused with the number of textures in an
/// array type image.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_unorm8ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                   size:(MTLSize)size;

/// Returns a \c MPSTemporaryImage allocated for usage on \c buffer with a
/// \c MPSImageFeatureChannelFormatFloat16 pixel format and with the \c width, \c height and
/// \c channels parameters.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_float16ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                   width:(NSUInteger)width height:(NSUInteger)height
                                                channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage allocated for usage on \c buffer with a descriptor built with a
/// \c MPSImageFeatureChannelFormatFloat16 pixel format and \c size. The depth property of \c size
/// is interpreted to be the number of channels, not to be confused with the number of textures in
/// an array type image.
///
/// @note The texture is not allocated until the first time the MPSTemporaryImage object is used by
/// an MPSCNNKernel object or until the first time the texture property is read.
+ (MPSTemporaryImage *)pnk_float16ImageWithCommandBuffer:(id<MTLCommandBuffer>)buffer
                                                    size:(MTLSize)size;

@end

#endif // PNK_USE_MPS

NS_ASSUME_NONNULL_END
