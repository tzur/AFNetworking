// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a tree layer. The tree layer is separated into groups of
/// trees such that each group receives its own motion vector.
@interface PNKImageMotionTreeLayer : NSObject<PNKImageMotionLayer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the segmentation map, number of samples and motion amplitude.
///
/// @param segmentation Segmentation map. Pixels with value \c pnk::LayerTypeTrees are assumed to
/// belong to trees.
///
/// @param numberOfSamples Number of samples in time used to simulate the movement of a tree tip.
/// Each sample corresponds to a single frame. The movement is periodical with period of
/// \c numberOfSamples samples (frames). \c numberOfSamples must be a power of 2.
///
/// @param amplitude Amplitude of tree tip oscillation.
- (instancetype)initWithSegmentation:(const cv::Mat &)segmentation
                     numberOfSamples:(NSUInteger)numberOfSamples
                           amplitude:(CGFloat)amplitude NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
