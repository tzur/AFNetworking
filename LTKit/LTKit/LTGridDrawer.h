// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

@class LTFbo;

/// @class LTGridDrawer
///
/// Class for efficiently drawing grids (when the maximal size of grid is known).
@interface LTGridDrawer : NSObject

/// Initializes the grid drawer for a grid with the given number of cells in each dimension.
- (id)initWithSize:(CGSize)size;

/// Draws the subgrid \c region into the given framebuffer. The region is defined in the grid's
/// coordinate system.
- (void)drawSubGridInRegion:(CGRect)region inFramebuffer:(LTFbo *)fbo;

/// Draws the subgrid \c region in a screen framebuffer with the given size.
///
/// @note this method assumes that the framebuffer/renderbuffer is already bound for drawing.
/// @note drawing will match the target coordinate system.
- (void)drawSubGridInRegion:(CGRect)region inFramebufferWithSize:(CGSize)size;

/// Base color of the grid, rgba with premultiplied alpha. Default is white (1,1,1,1).
@property (nonatomic) GLKVector4 color;

/// Opacity of the grid. This stacks together (multiply) with the alpha channel of the color.
/// Default is 1.
@property (nonatomic) CGFloat opacity;

/// Width, in pixels, of the border of each grid cell. This corresponds to half the width of the
/// grid lines, as each line consists of the two borders of neighboring cells. Default is 1.
@property (nonatomic) NSUInteger width;

@end
