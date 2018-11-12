// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

/// Category which adds a factory on top of LTTexture's abstract class. The factory chooses the
/// appropriate \c LTTexture subclass to instantiate, based on hardware compatibilities and
/// performance considerations.
@interface LTTexture (Factory)

/// Creates an empty texture on the GPU. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if texture creation failed.
///
/// @param size size of the texture. Must be integral.
///
/// @param pixelFormat pixel format the texture is stored in the GPU with. The format must be
/// supported on the target platform, or an \c NSInvalidArgumentException will be thrown.
///
/// @param maxMipmapLevel maximal mipmap level, with \c 0 meaning that only a single level exists.
///
/// @param allocateMemory an optimization recommendation to implementors of this class. If set to
/// \c YES, the texture's memory will be allocated on the GPU (but will not be initialized - see
/// note). Otherwise, the implementation will try to create a texture object only without allocating
/// the memory, and a call to \c load: or \c loadRect:fromImage: will be required to allocate
/// memory on the device.
///
/// @note The texture memory is not allocated until a call to \c load: or \c loadRect: is made, and
/// only the affected regions are set to be in a defined state. Calling \c storeRect:toImage: with
/// an uninitialized rect will return an undefined result.
+ (instancetype)textureWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
                 maxMipmapLevel:(GLint)maxMipmapLevel
                 allocateMemory:(BOOL)allocateMemory;

/// Creates an empty texture on the GPU without mipmap. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if texture creation failed. This is a convenience method which
/// is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:size pixelFormat:pixelFormat maxMipmapLevel:0
///             allocateMemory:allocateMemory];
/// @endcode
+ (instancetype)textureWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
                 allocateMemory:(BOOL)allocateMemory;

/// Allocates a texture with the \c size and \c pixelFormat properties suitable for the given
/// \c image, and loads the \c image to the texture. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has
/// failed.
+ (instancetype)textureWithImage:(const cv::Mat &)image;

/// Allocates a texture with the \c size and \c pixelFormat properties suitable for the given
/// \c image, and loads the \c image to the texture. Throws \c LTGLException with
/// \c kLTOpenGLRuntimeErrorException if the texture cannot be created or if image loading has
/// failed.
+ (instancetype)textureWithUIImage:(UIImage *)image;

/// Allocates a texture with the \c size and \c pixelFormat properties suitable for the given
/// \c image, and loads the \c image to the texture. If \c backgroundColor is set, the returned
/// texture will first be filled with the given color and then the image will be drawn over it using
/// normal blending mode. Otherwise no filling will be made prior to the drawing, potentially
/// preserving the transparency of the image.
+ (instancetype)textureWithUIImage:(UIImage *)image backgroundColor:(UIColor *)backgroundColor;

/// Creates a new byte precision, 4 channels RGBA texture with the given \c size and allocates its
/// memory. This is a convenience method which is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:size pixelFormat:LTGLPixelFormatRGBA8Unorm maxMipmapLevel:0
///             allocateMemory:YES];
/// @endcode
+ (instancetype)byteRGBATextureWithSize:(CGSize)size;

/// Creates a new byte precision, 1 channels R texture with the given \c size and allocates its
/// memory. This is a convenience method which is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:size pixelFormat:LTGLPixelFormatR8Unorm maxMipmapLevel:0
///             allocateMemory:YES];
/// @endcode
+ (instancetype)byteRedTextureWithSize:(CGSize)size;

/// Creates a new half-float precision, 4 channels RGBA texture with the given \c size and allocates
/// its memory. This is a convenience method which is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:size pixelFormat:LTGLPixelFormatRGBA16Float maxMipmapLevel:0
///             allocateMemory:YES];
/// @endcode
+ (instancetype)halfFloatRGBATextureWithSize:(CGSize)size;

/// Creates a new half-float precision, 1 channels R texture with the given \c size and allocates
/// its memory. This is a convenience method which is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:size pixelFormat:LTGLPixelFormatRG16Float maxMipmapLevel:0
///             allocateMemory:YES];
/// @endcode
+ (instancetype)halfFloatRedTextureWithSize:(CGSize)size;

/// Creates a new, allocated texture with \c size, \c pixelFormat and \c maxMipmapLevel similar to
/// the given \c texture. This is a convenience method which is similar to calling:
///
/// @code
/// [LTTexture textureWithSize:texture.size pixelFormat:texture.pixelFormat
///             maxMipmapLevel:texture.maxMipmapLevel
///             allocateMemory:YES];
/// @endcode
+ (instancetype)textureWithPropertiesOf:(LTTexture *)texture;

/// Creates a new, allocated texture with the given \c size. \c pixelFormat and \c maxMipmapLevel
/// are similar to the given \c texture. This is a convenience method which is similar to calling:
///
/// @code
/// return [self textureWithSize:size pixelFormat:texture.pixelFormat
///               maxMipmapLevel:texture.maxMipmapLevel
///               allocateMemory:YES];
/// @endcode
+ (instancetype)textureWithSize:(CGSize)size andPropertiesOfTexture:(LTTexture *)texture;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// image, and loads the \c image to the texture as the base level (0).
/// The mipmap will be automatically generated based on the given \c image with number of levels
/// equal to \c log2(MAX(image.size.width, image.size.height)).
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
///
/// @param image base level mipmap image. Each dimension of the image must be a power of two on
/// OpenGL ES versions lower than 3.0.
+ (instancetype)textureWithBaseLevelMipmapImage:(const cv::Mat &)image;

/// Allocates a texture with the \c size, \c precision and \c channels properties of the given \c
/// images, and loads the \c images one by one to consecutive mipmap levels, starting from the base
/// level 0.
///
/// @param images images to load to the mipmap. All images must have the same \c precision and \c
/// channels. Let \c (w[0], h[0]) be the dimensions of the base level, and \c (w[i], h[i]) the
/// dimensions of level \c i, then the following relations <tt>w[i] = floor(w[i - 1] / 2)</tt> and
/// <tt>h[i] = floor(h[i - 1] / 2)</tt> must hold. The given images may not create a complete
/// mipmap, hence the number of images can be lower or equal to \c log2(MAX(w[0], h[0])).
///
/// @note \c w[0] and \c h[0] must be a power of two on OpenGL ES versions lower than 3.0.
///
/// Throws \c LTGLException with \c kLTOpenGLRuntimeErrorException if the texture cannot be created
/// or if image loading has failed.
+ (instancetype)textureWithMipmapImages:(const Matrices &)images;

/// Creates a new texture with size and pixel format derived from the given \c pixelBuffer.
/// If possible, the created texture is backed by the pixel buffer. Otherwise, the data is copied
/// into the texture.
///
/// Throws \c LTGLException if the texture cannot be created, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note take take extra care when referencing \c pixelBuffer outside of this object.
/// GPU - CPU synchronization falls into your responsibility.
+ (instancetype)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// Creates a new texture with size and pixel format derived from a plane with index \c planeIndex
/// of the given planar \c pixelBuffer. If possible, the created texture is backed by the pixel
/// buffer. Otherwise, the data is copied into the texture.
///
/// Throws \c LTGLException if the texture cannot be created, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note take take extra care when referencing \c pixelBuffer outside of this object.
/// GPU - CPU synchronization falls into your responsibility.
+ (instancetype)textureWithPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(size_t)planeIndex;

/// Creates a new texture from the given Metal \c texture. If possible, the created texture shares
/// the same memory as the \c texture. Otherwise, the data is copied into the created texture.
/// The \c storageMode of the \c texture must be \c MTLStorageModeShared.
///
/// Throws \c LTGLException if the texture cannot be created, or if the build target doesn't support
/// Metal.
///
/// @note take extra care when referencing the \c texture outside of this object.
/// GPU - CPU synchronization falls into your responsibility.
///
/// @note the content produced by the commited \c MTBCommandBuffers, which renders to the
/// \c texture, is reflected in the returned texture. This happens automatically without any
/// explicit synchronization.
+ (instancetype)textureWithMTLTexture:(id<MTLTexture>)texture;

@end

NS_ASSUME_NONNULL_END
