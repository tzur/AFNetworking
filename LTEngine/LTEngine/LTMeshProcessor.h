// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTOneShotBaseImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Processor for drawing a texture placed on a grid mesh constructed using a mesh displacement map.
/// The displacement map is represented by the \c meshDisplacementTexture and can be adjusted by
/// manipulating this texture. The displacement texture is mapped to deform a specific area in the
/// input texture using a given displacement source rect. The rest of the input texture area will be
/// processed without displacement.
@interface LTMeshProcessor : LTOneShotBaseImageProcessor

/// Initializes with the given \c input texture, the given \c meshDisplacementTexture and the given
/// \c output texture. A passthrough fragment shader is used for drawing. The displacement map soure
/// rect is set to be the entire \c input size rect. \c meshDisplacementTexture must have at least
/// two channels (only the first two will be considrered) of half-float precision.
- (instancetype)initWithInput:(LTTexture *)input
      meshDisplacementTexture:(LTTexture *)meshDisplacementTexture output:(LTTexture *)output;

/// Initializes with the given \c fragmentSource, the given \c input texture the given \c
/// meshDisplacementTexture and the given \c output texture. The displacement map soure rect is set
/// to be the entire \c input size rect. \c meshDisplacementTexture must have at least two channels
/// (only the first two will be considrered) of half-float precision.
- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
               meshDisplacementTexture:(LTTexture *)meshDisplacementTexture
                                output:(LTTexture *)output;

/// Initializes with the given \c fragmentSource, the given \c input texture, the given \c
/// displacementSourceRect, the given \c meshDisplacementTexture and the given \c output texture. \c
/// displacementSourceRect must be inclusively contained in the \c input size rect. \c
/// \c meshDisplacementTexture must have at least two channels (only the first two will be
/// considrered) of half-float precision.
- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
                displacementSourceRect:(CGRect)displacementSourceRect
               meshDisplacementTexture:(LTTexture *)meshDisplacementTexture
                                output:(LTTexture *)output NS_DESIGNATED_INITIALIZER;

/// Mesh displacement texture used to alter the mesh vertices. The warp applied to the mesh is
/// according to the content of this texture, as offsets (in normalized texture coordinates) of the
/// mesh vertices covering the texture.
///
/// @see \c LTMeshDrawer.
@property (readonly, nonatomic) LTTexture *meshDisplacementTexture;

@end

NS_ASSUME_NONNULL_END
