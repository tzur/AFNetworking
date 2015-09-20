// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTextureDrawer.h"

@class LTFbo, LTRotatedRect;

/// Protocol for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, with additional draw methods for drawing a single rotated rectangle
/// or an axis-aligned one to a bound framebuffer or screenbuffer.
@protocol LTSingleRectDrawer <NSObject>

/// @see \c drawRect:inFramebuffer:fromRect:, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebuffer:(LTFbo *)fbo
        fromRotatedRect:(LTRotatedRect *)sourceRect;

/// @see {drawRect:inFramebufferWithSize:fromRect:}, but with \c LTRotatedRects as arguments.
- (void)drawRotatedRect:(LTRotatedRect *)targetRect inFramebufferWithSize:(CGSize)size
        fromRotatedRect:(LTRotatedRect *)sourceRect;

@end

/// Class for drawing rectangular regions from a source texture into a rectangular region
/// of a target framebuffer, optimized for drawing one rectangle at a time.
@interface LTSingleRectDrawer : LTTextureDrawer <LTSingleRectDrawer>
@end
