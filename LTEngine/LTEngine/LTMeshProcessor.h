// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTOneShotBaseImageProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Processor for drawing a texture placed on a grid mesh constructed using a mesh displacement map.
/// The displacement map is represented by the \c meshDisplacementTexture and can be adjusted by
/// manipulating this texture.
@interface LTMeshProcessor : LTOneShotBaseImageProcessor

/// Initializes with the given \c input texture, the given \c meshDisplacementTexture and the given
/// \c output texture. A passthrough fragment shader is used for drawing. \c meshDisplacementTexture
/// must have an \c LTGLPixelFormatRGBA16Float pixel format.
- (instancetype)initWithInput:(LTTexture *)input
      meshDisplacementTexture:(LTTexture *)meshDisplacementTexture output:(LTTexture *)output;

/// Initializes with the given \c fragmentSource, the given \c input texture the given \c
/// meshDisplacementTexture and the given \c output texture. \c meshDisplacementTexture must have an
/// \c LTGLPixelFormatRGBA16Float pixel format.
- (instancetype)initWithFragmentSource:(NSString *)fragmentSource input:(LTTexture *)input
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
