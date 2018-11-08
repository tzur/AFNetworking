// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzamn.

#import "LTTextureDrawer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for drawing a warped texture on a target framebuffer. The warp applied is according to
/// the displacement texture containing the offsets (in normalized texture coordinates) of the mesh
/// vertices covering the texture. The displacement can be mapped to a specific subarea on the
/// source texture using a given mesh source rect. The rest of the source texture area will be drawn
/// without displacement.
@interface LTMeshDrawer : NSObject <LTTextureDrawer>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithProgram:(LTProgram *)program
                  sourceTexture:(LTTexture *)texture NS_UNAVAILABLE;

- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)texture
              auxiliaryTextures:(NSDictionary *)uniformToAuxiliaryTexture NS_UNAVAILABLE;

/// Initializes the drawer with the given source texture, mesh displacement texture, the passthrough
/// fragment shader and the \c sourceTexture size rect as the mesh source texture. Mesh displacement
/// texture must have at least two channels (only the first two will be considrered) of half-float
/// precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture;

/// Initializes the drawer with the given source texture, the given mesh source rectangle, the given
/// mesh displacement texture amd the passthrough fragment shader. Mesh source rect must be
/// inclusively contained in the source texture size rect. Mesh displacement texture must have at
/// least two channels (only the first two will be considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                       meshSourceRect:(CGRect)meshSourceRect
                          meshTexture:(LTTexture *)meshTexture;

/// Initializes the drawer with the given source texture, mesh displacement texture, the given
/// fragment shader, the mesh texture and the \c sourceTexture size rect as the mesh source texture.
/// The mesh displacement texture must have at least two channels (only the first two will be
/// considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                          meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource;

/// Initializes the drawer with the given source texture, the given mesh source rectangle, the given
/// mesh displacement texture and the given fragment shader. Mesh source rect must be inclusively
/// contained in the source texture size rect. Mesh displacement texture must have at least two
/// channels (only the first two will be considrered) of half-float precision.
- (instancetype)initWithSourceTexture:(LTTexture *)sourceTexture
                       meshSourceRect:(CGRect)meshSourceRect
                          meshTexture:(LTTexture *)meshTexture
                       fragmentSource:(NSString *)fragmentSource NS_DESIGNATED_INITIALIZER;

/// When set to \c YES, only the wireframe of the underlying mesh will be drawn.
///
/// @important should only be used for debug purposes.
@property (nonatomic) BOOL drawWireframe;

@end

NS_ASSUME_NONNULL_END
