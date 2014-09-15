// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

/// Class for drawing a warped texture on a target framebuffer. The warp applied is according to
/// the displacement texture containing the offsets (in normalized texture coordinates) of the mesh
/// vertices covering the texture.
@interface LTMeshDrawer : LTTextureDrawer

/// Initializes the drawer with the given source texture, mesh displacement texture and the
/// passthrough fragment shader. The size of the mesh displacement texture determines the number of
/// vertices used.
///
/// @note The mesh displacement texture should have at least two channels (only the first two will
/// be considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture;

/// Initializes the drawer with the given source texture, mesh displacement texture and the given
/// fragment shader.
///
/// @note The mesh displacement texture should have at least two channels (only the first two will
/// be considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource;

/// When set to \c YES, only the wireframe of the underlying mesh will be drawn.
@property (nonatomic) BOOL drawWireframe;

@end
