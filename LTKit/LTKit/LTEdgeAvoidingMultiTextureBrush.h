// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTMultiTextureBrush.h"

/// @class LTEdgeAvoidingMultiTextureBrush
///
/// An class representing a texture brush used by the \c LTPainter, for edge-avoiding painting using
/// a texture randomally picked from an array of RGBA texture. The texture is blended to the target
/// canvas according to the brush flow and opacity properties.
/// This brush is different than the regular \c LTEdgeAvoidingBrush, as it uses the rgb difference
/// between the target intensity and the color of either the \c inputTexture or the target canvas
/// (framebuffer) as the edge-avoiding factor.
///
/// @see \c LTTextureBrush for more information.
@interface LTEdgeAvoidingMultiTextureBrush : LTMultiTextureBrush

/// Texture of the base image (for color distance and edge-avoiding paint). When set to \c nil, the
/// brush will use the target framebuffer color instead. Default is \c nil.
@property (strong, nonatomic) LTTexture *inputTexture;

/// Edge Avoiding sigma parameter. The lower the value of this parameter, the stronger the
/// edge-avoiding effect will be. Must be in range [0.01,1], default is \c 1 (not edge-avoiding).
@property (nonatomic) CGFloat sigma;
LTPropertyDeclare(CGFloat, sigma, Sigma)

@end
