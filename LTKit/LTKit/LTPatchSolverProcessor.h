// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTRotatedRect, LTTexture;

/// Processor for solving the Poisson equation. The processor is given a mask, source and target
/// textures, and calculates a result to the equation given the boundary condition T - S on the
/// mask's boundary.
@interface LTPatchSolverProcessor : NSObject <LTImageProcessor>

/// Initializes with mask, source texture, target texture and an output texture. The output texture
/// must have the larger dimension to be a power of two and with half-float precision.
- (instancetype)initWithMask:(LTTexture *)mask source:(LTTexture *)source
                      target:(LTTexture *)target output:(LTTexture *)output;

/// Refreshes the internal mask cache. One must call this method if the mask contents has been
/// changed after initialization.
- (void)maskUpdated;

/// Rotated rect defining a region of interest in the source texture, which the data is copied from.
/// The default value is an axis aligned rect of (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Rotated rect defining a region of interest in the target texture, where the data is copied to.
/// Note that the size and orientation of the rect can be different than \c sourceRect, which will
/// cause a warping of the source rect to this rect. The default value is an axis aligned rect of
/// (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *targetRect;

@end
