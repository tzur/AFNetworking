// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTFboAttachment.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents an OpenGL renderbuffer, whose storage is allocated using Core Animation and shared
/// between the renderbuffer and an \c EAGLDrawable.
///
/// @important the renderbuffer storage cannot be changed after being allocated. If the drawable has
/// changed its size, the current renderbuffer should be destroyed and a new renderbuffer should be
/// allocated from the new drawable.
@interface LTRenderbuffer : NSObject <LTFboAttachment>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with a \c drawable that will share the renderbuffer storage. The \c drawable will
/// not be acquired by this object.
- (instancetype)initWithDrawable:(id<EAGLDrawable>)drawable NS_DESIGNATED_INITIALIZER;

/// Request the native window system to present this renderbuffer.
- (void)present;

@end

NS_ASSUME_NONNULL_END
