// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for drawing a warped texture on a target framebuffer. The warp applied is according to
/// the displacement texture containing the offsets (in normalized texture coordinates) of the mesh
/// vertices covering the texture. The displacement can be mapped to a specific sub area on the
/// source texture using a given mesh source rect. Drawing will only be available in that given
/// area.
@interface LTMeshBaseDrawer : LTTextureDrawer

- (instancetype)initWithProgram:(LTProgram *)program
                  sourceTexture:(LTTexture *)texture NS_UNAVAILABLE;

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
              auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture NS_UNAVAILABLE;

/// Initializes the drawer with the given source texture, the given mesh source rectangle, the given
/// mesh displacement texture and the given fragment shader. \c meshSourceRect must be inclusively
/// contained in the source texture size rect. Mesh displacement texture must have at least two
/// channels (only the first two will be considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                       meshSourceRect:(CGRect)meshSourceRect meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource NS_DESIGNATED_INITIALIZER;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the given
/// framebuffer. The rects are defined in the source and target coordinate systems accordingly, in
/// pixels. \c sourceRect must be inclusively contained in the mesh source rect.
///
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inFramebuffer:(LTFbo *)fbo fromRect:(CGRect)sourceRect;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in an already
/// bound offscreen framebuffer with the given size. The rects are defined in the source and target
/// coordinate systems accordingly, in pixels. \c sourceRect must be inclusively contained in the
/// mesh source rect.
///
/// This method is useful when drawing to a renderbuffer managed by a different class, for example
/// the \c LTView's content fbo.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect;

/// When set to \c YES, only the wireframe of the underlying mesh will be drawn.
///
/// @important should only be used for debug purposes.
@property (nonatomic) BOOL drawWireframe;

@end

NS_ASSUME_NONNULL_END
