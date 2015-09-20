// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTextureDrawer.h"

@class LTFbo, LTQuad;

/// Protocol for drawing quadrilateral regions from a source texture into a quadrilateral region
/// of a target framebuffer with additional draw methods for drawing a single quadrilateral to a
/// bound framebuffer or screenbuffer.
@protocol LTSingleQuadDrawer <NSObject>

/// @see \c drawRect:inFramebuffer:fromRect:, but with \c LTQuads as arguments.
- (void)drawQuad:(LTQuad *)targetQuad inFramebuffer:(LTFbo *)fbo fromQuad:(LTQuad *)sourceQuad;

/// @see {drawRect:inFramebufferWithSize:fromRect:}, but with \c LTQuads as arguments.
- (void)drawQuad:(LTQuad *)targetQuad inFramebufferWithSize:(CGSize)size
        fromQuad:(LTQuad *)sourceQuad;

@end

/// Class for drawing quadrilateral regions from a source texture into a quadrilateral region
/// of a target framebuffer, optimized for drawing one quadrilateral at a time.
@interface LTSingleQuadDrawer : LTTextureDrawer <LTSingleQuadDrawer>
@end
