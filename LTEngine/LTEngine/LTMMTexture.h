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
/// Raises \c LTGLException if the texture cannot be created, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a planar pixel buffer.
///
/// @note \c pixelBuffer is retained by this texture.
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/// Initializes a texture using the plane at index \c planeIndex of the given planar \c pixelBuffer
/// as texture's underlying storage. You must take extra care when referencing this pixel buffer
/// outside of this object. GPU - CPU synchronization falls into your responsibility.
///
/// Raises \c LTGLException if the texture cannot be created, and \c NSInvalidArgumentException if
/// \c pixelBuffer is a non-planar pixel buffer or \c planeIndex is out of bounds.
///
/// @note \c pixelBuffer is retained by this texture.
- (instancetype)initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer planeIndex:(size_t)planeIndex;

@end
