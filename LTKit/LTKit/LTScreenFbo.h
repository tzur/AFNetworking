// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTFbo.h"

/// Object for encapsulating an OpenGL framebuffer associated with a screen framebuffer. This should
/// be used when generating an FBO for a renderbuffer not backed by a texture, i.e a \c GLKView's
/// renderbuffer.
@interface LTScreenFbo : LTFbo

/// Initializes an fbo with the given size, which is associated with the currently bound
/// screen framebuffer. Upon binding, calling to \c bindAndDraw, this framebuffer will be bound, and
/// the current viewport (at time of initialization) will be set as well.
- (instancetype)initWithSize:(CGSize)size;

@end
