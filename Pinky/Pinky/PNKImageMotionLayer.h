// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Protocol to be implemented by layers capable of computing a time dependent displacement field.
@protocol PNKImageMotionLayer <NSObject>

/// Fills the \c displacements matrix with the displacements of the layer at time \c time. The
/// \c displacements matrix must have 2 channels (dx and dy) of half-float type. The size of
/// \c displacements must match \c imageSize. The displacements calculated by this method are
/// backwards: if a pixel <tt>(x, y)</tt> should move to the new position <tt>(x+dx, y+dy)</tt> then
/// the displacements matrix will contain <tt>(-dx, -dy)</tt> value in the position
/// <tt>(x+dx, y+dy)</tt>. All displacements are in normalized coordinates.
- (void)displacements:(cv::Mat *)displacements forTime:(NSTimeInterval)time;

/// Size of the image.
@property (readonly, nonatomic) cv::Size imageSize;

@end

NS_ASSUME_NONNULL_END
