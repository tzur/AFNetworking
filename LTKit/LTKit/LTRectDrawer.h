// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTFbo, LTProgram, LTTexture;

/// @class LTRectDrawer
///
/// Class for drawing rectangular regions from a source texture into a rectangular region of a
/// target framebuffer, an operation which is very common when using programs to perform image
/// processing operations.
@interface LTRectDrawer : NSObject

/// Initializes with the given program. The source texture must be set prior to drawing using the \c
/// setSourceTexture: method. The program must include the uniforms \c projection (projection
/// matrix), \c modelview (modelview matrix) and \c texture (texture matrix).
- (id)initWithProgram:(LTProgram *)program;

/// Designated initializer: initializes with the given program and source texture. The program must
/// include the uniforms \c projection (projection matrix), \c modelview (modelview matrix) and \c
/// texture (texture matrix).
- (id)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the given
/// framebuffer. The rects are defined in the source and target coordinate systems accordingly, in
/// pixels.
///
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in a screen
/// framebuffer with the given size. The rects are defined in the source and target coordinate
/// systems accordingly, in pixels.
///
/// This method is useful when drawing to a system-supplied renderbuffer, such in \c GLKView.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note drawing will match the target coordinate system. For example, on iOS drawing to targetRect
/// of (0,0,1,1) will draw on the top left pixel, while on OSX the same targetRect will draw on the
/// bottom left pixel.
///
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect;

/// Sets the source texture to the given \c texture. If the texture is equal to the current
/// configured texture, no action will be done.
- (void)setSourceTexture:(LTTexture *)texture;

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
