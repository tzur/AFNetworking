// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

/// A texture class representing a memory mapped based texture.
///
/// The GPU referenced texture and the CPU referenced pixel buffer share the storage allocation of
/// the \c LTMMTexture object. The pixel buffer is either allocated internally, or provided
/// externally (via \c initWithPixelBuffer: or \c initWithPixelBuffer:planeIndex: initializers).
///
/// As they share the same storage, any changes to the pixels of the texture object within the GPU
/// are reflected in the texture object reference in the CPU, and vice versa.
///
/// This enables for swift transitions between GPU and CPU processing of the \c LTMMTexture.
///
/// @note OpenGL uses a deferred pipeline and synchronous calls to GPU processing occur at a later
/// time asynchronously. This may cause inconsistent behavior when performing GPU processing
/// immediately followed by CPU processing. To overcome this, \c LTMMTexture introduces internal
/// synchronization that blocks CPU processes if any GPU processing is taking place.
///
/// @note <b>The synchronization mentioned above works only when the pixel buffer backing this
/// texture is not accessed directly.</b> Otherwise, it is the caller's responsibility to handle
/// GPU - CPU synchronization.
@interface LTMMTexture : LTTexture

/// Initializes a texture using the given \c pixelBuffer as its underlying storage. You must take
/// extra care when referencing this pixel buffer outside of this object. GPU - CPU synchronization
/// falls into your responsibility.
///
/// Raises: \c LTGLException if the texture cannot be created or if the \c pixelBuffer is not backed
/// by IOSurface (when running on iOS 11 device), \c NSInvalidArgumentException if \c pixelBuffer is
/// a planar pixel buffer.
///
/// @note \c pixelBuffer is retained by this texture.
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// Initializes a texture using the plane at index \c planeIndex of the given planar \c pixelBuffer
/// as texture's underlying storage. You must take extra care when referencing this pixel buffer
/// outside of this object. GPU - CPU synchronization falls into your responsibility.
///
/// Raises: \c LTGLException if the texture cannot be created or if the \c pixelBuffer is not backed
/// by IOSurface (when running on iOS 11 device), \c NSInvalidArgumentException if \c pixelBuffer is
/// a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note \c pixelBuffer is retained by this texture.
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(size_t)planeIndex;

/// Initializes a texture from the given Metal \c texture. The created texture shares the same
/// memory as the \c texture when possible. \c iosurface property of the \c texture must be set and
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

/// Returns the pixel buffer that backs the content of this texture. This is a zero-copy operation.
///
/// All previous GPU operations involving writes to the texture complete before the pixel buffer is
/// returned. Future operations MUST be synchronized manually, at the sole responsibly of the
/// caller.
///
/// @note you <b>MUST NOT</b> write to the texture while holding the returned pixel buffer. The best
/// approach is to avoid using the texture at all after calling this function.
///
/// @see the documentation of <tt>-[LTTexture pixelBuffer]</tt>.
- (lt::Ref<CVPixelBufferRef>)pixelBuffer;

@end
