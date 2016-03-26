// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Protocol for 1D and 2D boundary condition. Implementors of this protocol define the strategy to
/// be used for computations where a signal is expanded over its boundaries. Such computations
/// include filtering with a kernel and sampling.
///
/// @important the boundary condition handles locations as a positions in a continuous grid. This
/// means that for a signal length of size \c N, a position of \c N - \c epsilon, where \c epsilon
/// is a very small value is still valid. If sampling from a integral grid is required, rounding
/// should follow this process.
@protocol LTBoundaryCondition <NSObject>

/// Boundary condition for a 1D signal.
///
/// @param location location in the signal. The location can be a non-integral value.
/// @param length length of the signal, which must be a positive number.
///
/// @return If the location falls inside the range [0, length), the original \c location will be
/// returned. Otherwise, the boundary condition will be applied.
+ (float)boundaryConditionForPosition:(float)location withSignalLength:(float)length;

/// Boundary condition for 2D signal. Since boundary condition is a strategy that is usually defined
/// on 1D signals, this method can usually be implemented by applying the 1D boundary condition on
/// both axes.
+ (LTVector2)boundaryConditionForPoint:(LTVector2)point withSignalSize:(CGSize)size;

@end

/// Returns a location with a symmetric boundary condition. For a signal of length N, the output
/// values will be in the range [0, N] (note that the interval is close).
///
/// Example: Given signal [1, 2, 3, 4] with signal length of 4, the values of the
/// boundary conditions for locations -3..5 will be: [4, 3, 2, 1, 2, 3, 4, 3, 2]. This is similar
/// to Matlab's \c symmetric boundary condition.
@interface LTSymmetricBoundaryCondition : NSObject <LTBoundaryCondition>
@end
