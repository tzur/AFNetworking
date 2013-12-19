// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTFbo;

/// @class LTGridDrawer
///
/// Class for efficiently drawing grids (when the maximal size of grid is known).
@interface LTGridDrawer : NSObject

/// Initializes the grid drawer for a grid with the given size.
- (id)initWithSize:(CGSize)size;

/// Draws the subgrid \c region into the given framebuffer. The region is defined in the grid's
/// coordinate system.
- (void)drawSubGridInRegion:(CGRect)region inFrameBuffer:(LTFbo *)fbo;

/// Draws the subgrid \c region in a framebuffer with the given size.
///
/// @note this method assumes that a framebuffer/renderbuffer is alraedy bound for drawing.
- (void)drawSubGridInRegion:(CGRect)region inFrameBufferWithSize:(CGSize)size;

/// Base color of the grid, rgba or grayscale with premultiplied alpha.
@property (strong, nonatomic) UIColor *color;

/// Opacity of the grid. This stacks together (multiply) with the alpha channel of the color.
@property (nonatomic) CGFloat opacity;

// Width of the grid lines, in pixels.
@property (nonatomic) NSUInteger width;

@end
