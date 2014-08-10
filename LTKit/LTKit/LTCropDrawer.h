// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTFbo, LTTexture;

#import "LTCropDrawerRect.h"

/// @class LTCropDrawer
///
/// Class for drawing axis-aligned rectangular regions from a source texture into a rectangular
/// region of a target framebuffer. This drawer provides a convenient method of drawing rotated and
/// flipped rectangles by mapping the target and source rectangle corners.
@interface LTCropDrawer : NSObject

/// Initializes the drawer with the given source texture.
- (instancetype)initWithTexture:(LTTexture *)texture;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the given
/// framebuffer. The rects are defined in the source and target coordinate systems accordingly, in
/// pixels, and each corner in the \c targetRect is mapped to its counterpart in the \c sourceRect.
- (void)drawRect:(LTCropDrawerRect)targetRect inFramebuffer:(LTFbo *)fbo
        fromRect:(LTCropDrawerRect)sourceRect;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in the
/// currently bound framebuffer with the given size. The rects are defined in the source and target
/// coordinate systems accordingly, in pixels, and each corner in the \c targetRect is mapped to its
/// counterpart in the \c sourceRect.
- (void)drawRect:(LTCropDrawerRect)targetRect inFramebufferWithSize:(CGSize)size
        fromRect:(LTCropDrawerRect)sourceRect;

@end
