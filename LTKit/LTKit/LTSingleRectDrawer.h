// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

/// @protocol LTSingleRectDrawer
///
/// Protocol for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, with additional draw methods for drawing a single rotated rectangle
/// or an axis-aligned one to a bound framebuffer or screenbuffer.
@protocol LTSingleRectDrawer <LTProcessingDrawer>

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in an already
/// bound offscreen framebuffer with the given size. The rects are defined in the source and target
/// coordinate systems accordingly, in pixels.
///
/// This method is useful when drawing to a renderbuffer managed by a different class, for example
/// the \c LTView's content fbo.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inFramebufferWithSize:(CGSize)size fromRect:(CGRect)sourceRect;

/// @see {drawRect:inFramebufferWithSize:fromRect:}, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect;

@end

/// @class LTSingleRectDrawer
///
/// Class for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, optimized for drawing one rectangle at a time.
@interface LTSingleRectDrawer : LTTextureDrawer <LTSingleRectDrawer>
@end
