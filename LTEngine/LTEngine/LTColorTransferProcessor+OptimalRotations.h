// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTColorTransferProcessor.h"

NS_ASSUME_NONNULL_BEGIN

/// Category adding a set of the optimal rotations that can be used instead of random rotations,
/// lowering the number of iterations needed to achieve visually pleasing results.
@interface LTColorTransferProcessor (OptimalRotations)

/// Returns the optimal rotation scheme w.r.t maximizing the Euclidean distance for every new
/// orthonormal rotation's base vectors from all the previous rotation bases in the scheme.
- (const std::vector<const cv::Mat1f>)optimalRotations;

@end

NS_ASSUME_NONNULL_END
