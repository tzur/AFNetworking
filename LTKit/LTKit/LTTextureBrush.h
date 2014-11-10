// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

@class LTTexture;

/// @class LTTextureBrush
///
/// An abstract class representing a texture brush used by the \c LTPainter, for painting using
/// RGBA textures. The texture is blended to the target canvas according to the brush flow and
/// opacity properties.
///
/// @note Due to the nature of this brush, it behaves correctly when drawing to RGBA framebuffers,
/// and in the \c LTPainterTargetModeDirectStroke mode.
/// @note the default value of the spacing property is changed to 2.
@interface LTTextureBrush : LTBrush

/// If \c YES, treats the target canvas as having premultiplied alpha.
/// If \c NO, treats the target canvas as having non-premultiplied alpha.
/// The input texture itself is always treated as having premultiplied alpha.
@property (nonatomic) BOOL premultipliedAlpha;

@end
