// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

@protocol LTSingleRectDrawer <LTProcessingDrawer>

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in a screen
/// framebuffer with the given size. The rects are defined in the source and target coordinate
/// systems accordingly, in pixels.
///
/// This method is useful when drawing to a system-supplied renderbuffer, such in \c GLKView.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note drawing will match the target coordinate system. For example, on iOS drawing to targetRect
/// of (0,0,1,1) will draw on the top left pixel, while on OSX the same targetRect will draw on the
/// bottom left pixel.
///
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect;

/// @see {drawRect:inScreenFramebufferWithSize:fromRect:}, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inScreenFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect;

/// Draws the \c sourceRect region in the source texture into the \c targetRect region in an already
/// bound offscreen framebuffer with the given size. The rects are defined in the source and target
/// coordinate systems accordingly, in pixels.
///
/// This method is useful when drawing to a renderbuffer managed by a different class, for example
/// the \c LTView's content fbo.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note \c sourceTexture must be set prior to drawing, otherwise an exception will be thrown.
- (void)drawRect:(CGRect)targetRect inBoundFramebufferWithSize:(CGSize)size
        fromRect:(CGRect)sourceRect;

/// @see {drawRect:inBoundFramebufferWithSize:fromRect:}, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inBoundFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect;

@end

/// @class LTSingleRectDrawer
///
/// Class for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, optimized for drawing one rectangle at a time.
@interface LTSingleRectDrawer : LTTextureDrawer <LTSingleRectDrawer>
@end
