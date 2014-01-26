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
/// @param channels number of channels of the texture.
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
                       channels:(LTTextureChannels)channels allocateMemory:(BOOL)allocateMemory;

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

@end
