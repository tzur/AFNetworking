// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

NS_ASSUME_NONNULL_BEGIN

/// Returns the number of elements required for the buffer such that the number is larger than the
/// number of elements in \c matrix and is a multiple of 4 so that it matches the number of channels
/// in an MPSImage.
NSUInteger PNKImageAlignedBufferElementsFromMatrix(const cv::Mat &matrix);

/// Fills the content of \c buffer with a half float representation of the content of \c parameters.
/// \c parameters type must be \c CV_16FC1 or \c CV_32FC1.
void PNKFillHalfFloatBuffer(id<MTLBuffer> buffer, const cv::Mat &parameters);

/// Creates a new \c MTLBuffer on \c device and fills it with the elements of \c parameters matrix
/// converted to half-float.
id<MTLBuffer> PNKHalfBufferFromFloatVector(id<MTLDevice> device, const cv::Mat1f &parameters);

NS_ASSUME_NONNULL_END
