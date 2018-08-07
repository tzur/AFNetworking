// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

NS_ASSUME_NONNULL_BEGIN

/// Category for conveniently copying data between \c MPSImage objects and OpenCV matrices.
@interface MPSImage (OpenCV)

/// Returns an \c MPSImage for use with \c device filled with the data copied from \c cv::Mat.
///
/// @note one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
+ (MPSImage *)mtb_imageWithDevice:(id<MTLDevice>)device mat:(const cv::Mat &)mat;

/// Copies the data of the \c MPSImage to a \c cv::Mat.
///
/// @note one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
- (void)mtb_copyToMat:(cv::Mat *)mat;

/// Copies the data of the \c MPSImage and returns it as a \c cv::Mat.
///
/// @note one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
- (cv::Mat)mtb_mat;

/// Copies the data of a \c cv::Mat to the \c MPSImage.
///
/// @note one must wait until all writes have been completed before calling this function to
/// avoid undefined behavior.
- (void)mtb_copyFromMat:(const cv::Mat &)mat;

@end

NS_ASSUME_NONNULL_END
