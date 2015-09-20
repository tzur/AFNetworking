// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureBrush.h"

/// An class representing a texture brush used by the \c LTPainter, for painting using a texture
/// randomally picked from an array of RGBA texture. The texture is blended to the target canvas
/// according to the brush flow and opacity properties.
///
/// @see \c LTTextureBrush for more information.
@interface LTMultiTextureBrush : LTTextureBrush

/// Array of \c LTTextures used for painting. When painting, a texture will be randomally picked for
/// each brush tip. By default, this is an array with a single single-pixel white texture.
///
/// @note All textures must be of \c LTTextureFormatRGBA format, and have the same size.
@property (strong, nonatomic) NSArray *textures;

@end
