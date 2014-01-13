// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <GLKit/GLKMath.h>
#import <opencv2/core/core.hpp>

/// Protocol for 1D and 2D boundary condition. Implementors of this protocol define the strategy to
/// be used for computations where a signal is expanded over its boundaries. Such computations
/// include filtering with a kernel and sampling.
@protocol LTBoundaryCondition <NSObject>

/// Boundary condition for a 1D signal.
///
/// @param location location in the signal. The location can be a non-integral value.
/// @param length integral length of the signal.
///
/// @return If the location falls inside the range [0, length - 1], the original \c location will be
/// returned. Otherwise, the boundary condition will be applied.
+ (float)boundaryConditionForPosition:(float)location withSignalLength:(int)length;

/// Boundary condition for 2D signal. Since boundary condition is a strategy that is usually defined
/// on 1D signals, this method can usually be implemented by applying the 1D boundary condition on
/// both axes.
+ (GLKVector2)boundaryConditionForPoint:(GLKVector2)point withSignalSize:(cv::Size2i)size;

@end

/// @class LTSymmetricBoundaryCondition
///
/// Returns a location with a symmetric boundary condition.
/// Example: Given signal [1, 2, 3, 4]  with signal values at indices \c 0..3, the values of the
/// boundary conditions for locations -3..5 will be: [4, 3, 2, 1, 2, 3, 4, 3, 2]. This is similar
/// to Matlab's \c symmetric boundary condition.
@interface LTSymmetricBoundaryCondition : NSObject <LTBoundaryCondition>
@end
