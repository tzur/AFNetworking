// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Class representing a patch of displacement created by waves on a liquid surface.
@interface PNKImageMotionWavePatch : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with \c patchSize. \c patchSize is the size (in pixels) of a square patch. It must
/// be a power of \c 2.
- (instancetype)initWithPatchSize:(NSUInteger)patchSize NS_DESIGNATED_INITIALIZER;

/// Returns matrix of wave-like displacements at \c time.
- (const cv::Mat &)displacementsForTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
