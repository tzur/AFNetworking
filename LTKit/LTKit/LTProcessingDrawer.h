// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTFbo, LTProgram, LTRotatedRect, LTTexture;

/// Protocol for drawers that can be used to process an image using the GPU.
@protocol LTProcessingDrawer <NSObject>

/// Initializes with the given program and source texture, with no auxiliary textures. The program
/// must include the uniforms \c projection (projection matrix), \c modelview (modelview matrix) \c
/// texture (texture matrix) and \c sourceTexture (the master source texture).
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture;

/// Designated initializer: initializes with the given program, source texture and auxiliary
/// textures. The source coordinate system of the drawer is defined by the source texture (when used
/// in the \c drawRect:inFramebuffer:fromRect: and \c drawRect:inScreenFramebufferWithSize:fromRect:
/// methods).
///
/// @param program program used while drawing. Must include the uniforms \c projection (projection
/// matrix), \c modelview (modelview matrix) and \c texture (texture matrix).
/// @param uniformToauxiliaryTexture mapping between uniform name (\c NSString) and its
/// corresponding \c LTTexture object.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
              auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the given
/// framebuffer. The rects are defined in the source and target coordinate systems accordingly, in
/// pixels.
///
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect;

/// @see \c drawRect:inFramebuffer:fromRect:, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebuffer:(LTFbo *)fbo
        fromRotatedRect:(LTRotatedRect *)sourceRect;

/// @see \c drawRect:inFramebuffer:fromRect:, but with \c NSArray of \c LTRotatedRects as arguments.
- (void)drawRotatedRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRotatedRects:(NSArray *)sourceRects;

/// Sets the source texture to the given \c texture. If the texture is equal to the current
/// configured texture, no action will be done. The given texture cannot be \c nil.
- (void)setSourceTexture:(LTTexture *)texture;

/// Sets auxiliary \c texture with the given sampler \c name as an input source to the drawer.
/// Both \c texture and \c name cannot be \c nil, and \c name cannot be \c sourceTexture.
- (void)setAuxiliaryTexture:(LTTexture *)texture withName:(NSString *)name;

/// Sets the underlying program's uniform value. Given uniform name cannot be {\c projection, \c
/// modelview, \c texture}.
///
/// @see \c -[LTProgram setUniform:withValue:].
- (void)setUniform:(NSString *)name withValue:(id)value;

/// Returns the underlying program's uniform value for the given \c name, or throws an exception if
/// the \c name is not a valid one.
- (id)uniformForName:(NSString *)name;

@end
