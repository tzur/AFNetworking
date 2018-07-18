// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a tree layer. The tree layer is separated into groups of
/// trees such that each group receives its own motion vector.
@interface PNKImageMotionTreeLayer : NSObject<PNKImageMotionLayer,
    PNKImageMotionSegmentationAwareLayer>;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the image size, number of samples and motion amplitude.
///
/// @param imageSize Size of the displacement map that will be created.
///
/// @param numberOfSamples Number of samples in time used to simulate the movement of a tree tip.
/// Each sample corresponds to a single frame. The movement is periodical with period of
/// \c numberOfSamples samples (frames). \c numberOfSamples must be a power of 2.
///
/// @param amplitude Maximal angle (in radians) of deviation of the straight line connecting a tree
/// root with the same tree tip from the vertical direction.
- (instancetype)initWithImageSize:(cv::Size)imageSize numberOfSamples:(NSUInteger)numberOfSamples
                        amplitude:(CGFloat)amplitude NS_DESIGNATED_INITIALIZER;

/// Update the layer with \c segmentationMap. \c segmentationMap size must match \c imageSize.
///
/// @note \c displacements:forTime: method will fail if called before calling
/// \c updateWithSegmentationMap: at least once.
- (void)updateWithSegmentationMap:(const cv::Mat1b &)segmentationMap;

/// Fills the \c displacements matrix with the displacements of the layer at time \c time. The
/// \c displacements matrix must have 2 channels (dx and dy) of half-float type. The size of
/// \c displacements must match \c imageSize. The displacements calculated by this method are
/// backwards: if a pixel <tt>(x, y)</tt> should move to the new position <tt>(x+dx, y+dy)</tt> then
/// the displacements matrix will contain <tt>(-dx, -dy)</tt> value in the position
/// <tt>(x+dx, y+dy)</tt>. All displacements are in normalized coordinates.
///
/// @note Some pixels that belong to the Tree layer in the \c segmentationMap will not belong to it
/// after the displacement is applied. Such pixels belong to the "hole" layer. To reflect this fact
/// the relevant pixels will get displacement values exceeding \c 1. Displacement values are
/// normalized, so \c 1 stands for full image size; such displacement is interpreted as "pixel comes
/// from outside the image" or, in other words, the "hole" layer.
- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
