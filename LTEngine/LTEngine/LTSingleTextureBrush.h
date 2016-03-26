// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

/// A class representing a texture brush used by the \c LTPainter, for painting using a single
/// RGBA texture. The texture is blended to the target canvas according to the brush flow and
/// opacity properties.
///
/// @see \c LTTextureBrush for more information.
@interface LTSingleTextureBrush : LTTextureBrush

/// Texture used by the brush. Its components must be \c LTGLPixelComponentsRGBA. By default, this
/// is a single-pixel, white texture.
@property (strong, nonatomic) LTTexture *texture;

@end
