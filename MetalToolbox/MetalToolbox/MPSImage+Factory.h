// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

NS_ASSUME_NONNULL_BEGIN

/// Category for conveniently creating \c MPSImage objects.
///
/// @note All methods in this category are memory-intensive as they require allocating a new
/// texture.
@interface MPSImage (Factory)

/// Returns an \c MPSImage with a descriptor built from the \c format, \c width, \c height and
/// \c channels parameters.
+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device format:(MPSImageFeatureChannelFormat)format
                            width:(NSUInteger)width height:(NSUInteger)height
                         channels:(NSUInteger)channels;

/// Returns an \c MPSImage with a descriptor built from the \c format and \c size parameters. The
/// depth property of \c size is interpreted to be the number of channels, not to be confused with
/// the number of textures in an array type image.
+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device format:(MPSImageFeatureChannelFormat)format
                             size:(MTLSize)size;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatUnorm8
/// pixel format and with the \c width, \c height and \c channels parameters.
+ (MPSImage *)mtb_unorm8ImageWithDevice:(id<MTLDevice>)device width:(NSUInteger)width
                                 height:(NSUInteger)height channels:(NSUInteger)channels;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatUnorm8
/// pixel format and \c size. The depth property of \c size is interpreted to be the number of
/// channels, not to be confused with the number of textures in an array type image.
+ (MPSImage *)mtb_unorm8ImageWithDevice:(id<MTLDevice>)device size:(MTLSize)size;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatFloat16
/// pixel format and with the \c width, \c height and \c channels parameters.
+ (MPSImage *)mtb_float16ImageWithDevice:(id<MTLDevice>)device width:(NSUInteger)width
                                  height:(NSUInteger)height channels:(NSUInteger)channels;

/// Returns an \c MPSImage with a descriptor built with a \c MPSImageFeatureChannelFormatFloat16
/// pixel format and \c size. The depth property of \c size is interpreted to be the number of
/// channels, not to be confused with the number of textures in an array type image.
+ (MPSImage *)mtb_float16ImageWithDevice:(id<MTLDevice>)device size:(MTLSize)size;

@end

NS_ASSUME_NONNULL_END
