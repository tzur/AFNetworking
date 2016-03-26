// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

@class LTFbo;

/// Protocol for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, with additional draw methods for drawing an array of rotated rectangles
/// to a bound framebuffer or screenbuffer.
@protocol LTMultiRectDrawer <NSObject>

/// @see \c drawRect:inFramebuffer:fromRect:, but with \c NSArray of \c LTRotatedRects as arguments.
///
/// @note \c targetRects and \c sourceRects must have the same number of elements.
- (void)drawRotatedRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRotatedRects:(NSArray *)sourceRects;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in an already
/// bound offscreen framebuffer with the given size. The rects are defined in the source and target
/// coordinate systems accordingly, in pixels.
///
/// This method is useful when drawing to a renderbuffer managed by a different class, for example
/// the \c LTView's content fbo.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
/// @note \c targetRects and \c sourceRects must have the same number of elements.
- (void)drawRotatedRects:(NSArray *)targetRects inFramebufferWithSize:(CGSize)size
        fromRotatedRects:(NSArray *)sourceRects;

@end

/// Class for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, optimized for drawing an array of rectangles each time.
@interface LTMultiRectDrawer : LTTextureDrawer <LTMultiRectDrawer>
@end
