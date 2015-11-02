// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTexture.h"

/// A texture class representing a memory mapped based texture.
///
/// The GPU referenced texture and the CPU referenced buffer share the storage allocation of the
/// \c LTMMTexture object.
///
/// As they share the same storage, any changes to the pixels of the texture object within the GPU
/// are reflected in the texture object reference in the CPU, and vice versa.
///
/// This enables for swift transitions between GPU and CPU processing of the \c LTMMTexture.
///
/// @note OpenGL uses a deferred pipeline and synchronous calls to GPU processing occur at a later
/// time asynchronously. This may cause inconsistent behavior when performing GPU processing
/// immediately followed by CPU processing. To overcome this, \c LTMMTexure introduces internal
/// synchronization that blocks CPU processes if any GPU processing is taking place.
@interface LTMMTexture : LTTexture
@end
