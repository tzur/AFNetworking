// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

/// A texture class representing an OpenGL based texture.
@interface LTGLTexture : LTTexture

/// Initializes a texture with the given \c size, \c pixelFormat and maximal mipmap level.
/// The texture's memory will be allocated on the GPU but will not be initialized.
- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
              maxMipmapLevel:(GLint)maxMipmapLevel;

/// Initializes a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture as the base level (0).
/// The mipmap will be automatically generated based on the given \c image with number of levels
/// equal to \c log2(MAX(image.size.width, image.size.height)).
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
///
/// @param image base level mipmap image. Each dimension of the image must be a power of two on
/// OpenGL ES versions lower than 3.0.
- (instancetype)initWithBaseLevelMipmapImage:(const cv::Mat &)image;

/// Initializes a texture with the \c size, \c precision and \c channels properties of the given \c
/// images, and loads the \c images one by one to consecutive mipmap levels, starting from the base
/// level 0.
///
/// @param images images to load to the mipmap. All images must have the same \c precision and \c
/// channels. Let \c (w[0], h[0]) be the dimensions of the base level, and \c (w[i], h[i]) the
/// dimensions of level \c i, then the following relation must hold <tt>w[i] = floor(w[i - 1] / 2)
/// </tt> and <tt>h[i] = floor(h[i - 1] / 2)</tt> must hold. The given images may not create a
/// complete mipmap, hence the number of images can be lower or equal to \c log2(MAX(w[0], h[0])).
///
/// @note \c w[0] and \c h[0] must be a power of two on OpenGL ES versions lower than 3.0.
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
- (instancetype)initWithMipmapImages:(const Matrices &)images;

/// Initializes a texture from the given Metal \c texture by copying \c texture's data. The
/// \c storageMode of the \c texture must be \c MTLStorageModeShared.
///
/// Throws \c LTGLException if the texture cannot be created, or if the build target doesn't support
/// Metal.
///
/// @note take extra care when referencing the \c texture outside of this object.
/// GPU - CPU synchronization falls into your responsibility.
///
/// @note the content produced by the commited \c MTBCommandBuffers, which renders to the
/// \c texture, is reflected in initialized texture. This happens automatically without any explicit
/// synchronization.
- (instancetype)initWithMTLTexture:(id<MTLTexture>)texture;

/// Initializes a new texture with size and pixel format derived from the given \c pixelBuffer, by
/// copying \c pixelBuffer's content into the texture.
///
/// Throws \c LTGLException if the texture cannot be created, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note take take extra care when referencing \c pixelBuffer outside of this object.
/// GPU - CPU synchronization falls into your responsibility.
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// Returns a \c Mat object from the given level of the texture. This is a heavy operation since it
/// requires duplicating the texture to a new memory location. The matrix type and size depends on
/// the texture's values, but the matrix will always contain 4 channels.
/// \c level must be less than or equal \c maxMipmapLevel.
///
/// @see storeRect:toImage: for more information.
- (cv::Mat)imageAtLevel:(NSUInteger)level;

/// Returns a newly allocates pixel buffer matching the format of this texture, that contains a copy
/// of the texture's content. For a mipmap, only the base level is used.
///
/// @see the documentation for <tt>-[LTTexture pixelBuffer]</tt>.
- (lt::Ref<CVPixelBufferRef>)pixelBuffer;

@end
