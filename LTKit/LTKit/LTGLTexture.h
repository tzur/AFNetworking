// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

/// A texture class representing an OpenGL based texture.
@interface LTGLTexture : LTTexture

/// Allocates a texture with the given \c size, \c precision, \c format and maximal number of
/// mipmap levels. The texture's memory will be allocated on the GPU but will not be initialized.
- (instancetype)initWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                      format:(LTTextureFormat)format maxMipmapLevel:(GLint)maxMipmapLevel;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture as the base level (0).
/// The mipmap will be automatically generated based on the given \c image with number of levels
/// equal to \c log2(MAX(image.size.width, image.size.height)).
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
///
/// @param image base level mipmap image. Each dimension of the image must be a power of two.
- (instancetype)initWithBaseLevelMipmapImage:(const cv::Mat &)image;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// images, and loads the \c images one by one to consecutive mipmap levels, starting from the base
/// level 0.
///
/// @param images images to load to the mipmap. All images must have the same \c precision and \c
/// channels. Let \c (w[0], h[0]) be the dimensions of the base level, and \c (w[i], h[i]) the
/// dimensions of level \c i, then \c w[0] and \c h[0] must be a power of two, and the relation
/// \c w[i] = w[i - 1] / 2 and \c h[i] = h[i - 1] / 2 must hold. The given images may not create a
/// complete mipmap, hence the number of images can be lower or equal to \c log2(MAX(w[0], h[0])).
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
- (instancetype)initWithMipmapImages:(const Matrices &)images;

/// Returns a \c Mat object from the given level of the texture. This is a heavy operation since it
/// requires duplicating the texture to a new memory location. The matrix type and size depends on
/// the texture's values, but the matrix will always contain 4 channels.
/// \c level must be less than or equal \c maxMipmapLevel.
///
/// @see storeRect:toImage: for more information.
- (cv::Mat)imageAtLevel:(NSUInteger)level;

@end
