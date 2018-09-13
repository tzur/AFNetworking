// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Value class that represents a subset of pixels of an image. Such subset is also known as a
/// segment or a superpixel.
@interface PNKInpaintingSuperPixel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with an array of pixel coordinates in the global coordinate system.
- (instancetype)initWithCoordinates:(const std::vector<cv::Point> &)coordinates;

/// Creates a new superpixel with an alternative \c center and the same \c offsets as for the
/// current superpixel.
- (instancetype)superPixelCenteredAt:(cv::Point)center;

/// Point such that set of the \c offsets applied to it define the set of points associated with
/// superpixel.
@property (readonly, nonatomic) cv::Point center;

/// Offsets of the pixels in the superpixel from \c center organized in a single-column matrix.
/// Each row contains in its 2 channels offset of a single pixel.
@property (readonly, nonatomic) cv::Mat2i offsets;

/// Bounding box of the pixels in the superpixel in the global coordinate system.
@property (readonly, nonatomic) cv::Rect boundingBox;

@end

NS_ASSUME_NONNULL_END
