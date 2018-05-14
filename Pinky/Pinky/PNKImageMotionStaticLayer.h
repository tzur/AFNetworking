// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayer.h"

NS_ASSUME_NONNULL_BEGIN

/// Class for calculating displacements of a static layer. This is a degenerate case such that the
/// displacements matrix is always filled with all zeroes.
@interface PNKImageMotionStaticLayer : NSObject <PNKImageMotionLayer>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the size of the original image.
- (instancetype)initWithImageSize:(cv::Size)imageSize NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
