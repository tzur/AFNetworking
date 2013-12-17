// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTFbo, LTProgram, LTTexture;

/// @class LTRectDrawer
///
/// Class for drawing rectangular regions from a source texture into a rectangular region of a
/// target framebuffer, an operation which is very common when using programs to perform image
/// processing operations.
@interface LTRectDrawer : NSObject

/// Initializes with the given program and source texture. The program must include the uniforms \c
/// projection (projection matrix), \c modelview (modelview matrix) and \c texture (texture matrix).
- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the given
/// framebuffer. The rects are defined in the source and target coordinate systems accordingly, in
/// pixels.
- (void)drawRect:(CGRect)targetRect inFrameBuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in a
/// framebuffer with the given size. The rects are defined in the source and target coordinate
/// systems accordingly, in pixels.
///
/// This method is useful when drawing to a system-supplied renderbuffer, such in \c GLKView.
///
/// @note this method assumes that a framebuffer/renderbuffer is already bound for drawing.
- (void)drawRect:(CGRect)targetRect inFrameBufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect;

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c -[LTProgram setUniform:withValue:].
- (void)setUniform:(NSString *)name withValue:(id)value;

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c setUniform:withValue:.
- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key;

@end
