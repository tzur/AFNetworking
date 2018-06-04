// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a tree tip with different random seeds resulting in
/// different displacement directions.
@interface PNKImageMotionTreeTipMovement : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with number of samples used to simulate the movement of a tree tip.
/// \c numberOfSamples must be a power of 2.
- (instancetype)initWithNumberOfSamples:(NSUInteger)numberOfSamples;

/// Returns a matrix of various displacements of a tree tip. This matrix contains \c 10 different
/// displacements in \c 10 rows. The matrix has \c numberOfSamples columns corresponding to
/// \c numberOfSamples samples (frames).
- (cv::Mat1f)treeTipDisplacements;
@end

NS_ASSUME_NONNULL_END
