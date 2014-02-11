// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

/// Category which adds a factory on top of LTTexture's abstract class. The factory chooses the
/// appropriate \c LTTexture subclass to instantiate, based on hardware compatabilities and
/// performance considerations.
@interface LTTexture (Factory)

/// Creates an empty texture on the GPU.  Throws \c LTGLException with \c
/// kLTOpenGLRuntimeErrorException if texture creation failed.
///
/// @param size size of the texture.
/// @param precision precision of the texture.
/// @param format format the texture is stored in the GPU with.
/// @param allocateMemory an optimization recommendation to implementors of this class. If set to \c
/// YES, the texture's memory will be allocated on the GPU (but will not be initialized - see note).
/// Otherwise, the implementation will try to create a texture object only without allocating the
/// memory, and a call to \c load: or \c loadRect:fromImage: will be required to allocate memory on
/// the device.
///
/// @note The texture memory is not allocated until a call to \c load: or \c loadRect: is made, and
/// only the affected regions are set to be in a defined state. Calling \c storeRect:toImage: with
/// an uninitialized rect will return an undefined result.
///
/// @note Designated initializer.
+ (instancetype)textureWithSize:(CGSize)size precision:(LTTexturePrecision)precision
                         format:(LTTextureFormat)format allocateMemory:(BOOL)allocateMemory;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture. Throws \c LTGLException with \c
/// kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has failed.
+ (instancetype)textureWithImage:(const cv::Mat &)image;

/// Creates a new byte precision, 4 channels RGBA texture with the given \c size and allocates its
/// memory. This is a convenience method which is similar to calling:
///
/// @code
/// [initWithSize:size precision:LTTexturePrecisionByte
///      channels:LTTextureChannelsRGBA allocateMemory:YES]
/// @endcode
+ (instancetype)byteRGBATextureWithSize:(CGSize)size;

/// Creates a new, allocated texture with \c size, \c precision and \c channels similar to the given
/// \c texture. This is a convenience method which is similar to calling:
///
/// @code
/// [initWithSize:texture.size precision:texture.precision
///      channels:texture.channels allocateMemory:YES]
/// @endcode
+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture as the base level (0).
/// The mipmap will be automatically generated based on the given \c image with number of levels
/// equal to \c log2(MAX(image.size.width, image.size.height)).
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
///
/// @param image base level mipmap image. Each dimension of the image must be a power of two.
+ (instancetype)textureWithBaseLevelMipmapImage:(const cv::Mat &)image;

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
+ (instancetype)textureWithMipmapImages:(const Matrices &)images;

@end
