// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for conveniently creating \c MPSTemporaryImage objects.
@interface MPSTemporaryImage (Factory)

/// Returns an \c MPSTemporaryImage with a descriptor built from the \c format, \c width, \c height
/// and \c channels parameters.
+ (MPSTemporaryImage *)mtb_temporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                    format:(MPSImageFeatureChannelFormat)format
                                                     width:(NSUInteger)width
                                                    height:(NSUInteger)height
                                                  channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage with a descriptor built from the \c format and \c size
/// parameters. The depth property of \c size is interpreted to be the number of channels, not to be
/// confused with the number of textures in an array type image.
+ (MPSTemporaryImage *)mtb_temporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                    format:(MPSImageFeatureChannelFormat)format
                                                      size:(MTLSize)size;

/// Returns an \c MPSTemporaryImage with a descriptor built with a
/// \c MPSImageFeatureChannelFormatUnorm8 pixel format and with the \c width, \c height and
/// \c channels parameters.
+ (MPSTemporaryImage *)mtb_unorm8TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                           width:(NSUInteger)width
                                                          height:(NSUInteger)height
                                                        channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage with a descriptor built with a
/// \c MPSImageFeatureChannelFormatUnorm8 pixel format and \c size. The depth property of \c size is
/// interpreted to be the number of channels, not to be confused with the number of textures in an
/// array type image.
+ (MPSTemporaryImage *)mtb_unorm8TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                                            size:(MTLSize)size;

/// Returns an \c MPSTemporaryImage with a descriptor built with a
/// \c MPSImageFeatureChannelFormatFloat16 pixel format and with the \c width, \c height and
/// \c channels parameters.
+ (MPSTemporaryImage *)
    mtb_float16TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                         width:(NSUInteger)width
                                        height:(NSUInteger)height
                                      channels:(NSUInteger)channels;

/// Returns an \c MPSTemporaryImage with a descriptor built with a
/// \c MPSImageFeatureChannelFormatFloat16 pixel format and \c size. The depth property of \c size
/// is interpreted to be the number of channels, not to be confused with the number of textures in
/// an array type image.
+ (MPSTemporaryImage *)
    mtb_float16TemporaryImageWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
                                          size:(MTLSize)size;

@end

NS_ASSUME_NONNULL_END
