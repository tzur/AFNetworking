// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTRotatedRect, LTTexture;

/// Processor for solving the Poisson equation. The processor is given a mask, source and target
/// textures, and calculates a result to the equation given the boundary condition T - S on the
/// mask's boundary.
@interface LTPatchSolverProcessor : LTImageProcessor

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c mask, \c source, \c target, and \c output textures. Identical to
/// calling:
///
/// @code
///   [[LTPatchSolverProcessor alloc] initWithMask:mask maskBoundaryThreshold:0 source:source
///                                         target:target output:output]
/// @endcode
- (instancetype)initWithMask:(LTTexture *)mask source:(LTTexture *)source
                      target:(LTTexture *)target output:(LTTexture *)output;

/// Initializes with the given \c mask, \c maskBoundaryThreshold, \c source, \c target, and
/// \c output. The \c maskBoundaryThreshold constitutes a threshold between the pixel values
/// considered to be inside the mask and the pixel values considered to be outside the mask when
/// extracting the mask boundary (@see the \c threshold property of \c LTPatchBoundaryProcessor for
/// more information). The \c mask texture must be of byte precision. \c maskBoundaryThreshold must
/// be in <tt>[0, 1]</tt>. The \c output texture must be of half-float precision.
- (instancetype)initWithMask:(LTTexture *)mask maskBoundaryThreshold:(CGFloat)maskBoundaryThreshold
                      source:(LTTexture *)source target:(LTTexture *)target
                      output:(LTTexture *)output NS_DESIGNATED_INITIALIZER;

/// Rotated rect defining a region of interest in the source texture, which the data is copied from.
/// The default value is an axis aligned rect of (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Rotated rect defining a region of interest in the target texture, where the data is copied to.
/// Note that the size and orientation of the rect can be different than \c sourceRect, which will
/// cause a warping of the source rect to this rect. The default value is an axis aligned rect of
/// (0, 0, source.width, source.height).
@property (strong, nonatomic) LTRotatedRect *targetRect;

/// \c YES if the \c sourceRect should be used in a mirrored way. The mirroring is performed along
/// the vertical line with <tt>x = 0.5</tt>, in texture coordinate space.
@property (nonatomic) BOOL flip;

@end
