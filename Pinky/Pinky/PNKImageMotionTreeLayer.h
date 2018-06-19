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
/// @param amplitude Amplitude of tree tip oscillation.
- (instancetype)initWithImageSize:(cv::Size)imageSize numberOfSamples:(NSUInteger)numberOfSamples
                        amplitude:(CGFloat)amplitude NS_DESIGNATED_INITIALIZER;

/// Segmentation map. The map's size must match \c imageSize. The segmentation map must be set
/// before calling the \c displacements:forTime: method.
@property (nonatomic) cv::Mat1b segmentation;

@end

NS_ASSUME_NONNULL_END
