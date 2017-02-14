// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboAttachable.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents an OpenGL renderbuffer, whose storage is allocated using one of the following
/// methods:
/// 1. Core Animation, so it can be shared between the renderbuffer and an \c EAGLDrawable.
/// 2. OpenGL ES renderbuffer storage. This allocation method supports a subset of the OpenGL ES
/// renderbuffer supported pixel formats.
///
/// @important the renderbuffer storage cannot be changed after being allocated. If the drawable has
/// changed its size, the current renderbuffer should be destroyed and a new renderbuffer should be
/// allocated from the new drawable.
@interface LTRenderbuffer : NSObject <LTFboAttachable>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c drawable that will share the renderbuffer storage. The \c drawable will
/// not be acquired by this object.
- (instancetype)initWithDrawable:(id<EAGLDrawable>)drawable NS_DESIGNATED_INITIALIZER;

/// Initializes with the given \c size and \c pixelFormat.
- (instancetype)initWithSize:(CGSize)size pixelFormat:(LTGLPixelFormat *)pixelFormat
    NS_DESIGNATED_INITIALIZER;

/// Request the native window system to present this renderbuffer.
///
/// @note works only for instances created using \c initWithDrawable: method.
- (void)present;

@end

NS_ASSUME_NONNULL_END
