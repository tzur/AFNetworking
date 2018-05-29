// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a grass layer. These displacements simulate a wave-like
/// movement along both X and Y axes.
@interface PNKImageMotionGrassLayer : NSObject<PNKImageMotionLayer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the size of the motion map, patch size and motion amplitude.
///
/// @param imageSize Size of the displacement map that will be created.
///
/// @param patchSize Size (in pixels) of a square patch of grass surface. This patch will be tiled
/// to cover the grass surface. \c patchSize must be a power of \c 2.
///
/// @param amplitude Amplitude of waves in the grass.
- (instancetype)initWithImageSize:(cv::Size)imageSize patchSize:(NSUInteger)patchSize
                        amplitude:(CGFloat)amplitude NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
