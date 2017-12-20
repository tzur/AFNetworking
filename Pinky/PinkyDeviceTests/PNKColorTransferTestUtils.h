// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Array of single-precision floats.
typedef std::vector<float> Floats;

/// Creates an \c MTLBuffer with correct padding from the given \c mat.
id<MTLBuffer> PNKCreateBufferFromMat(id<MTLDevice> device, const cv::Mat3f mat);

/// Creates an \c MTLBuffer representing the given 3x3 linear transform \c mat, with the correct
/// padding expected by Metal.
id<MTLBuffer> PNKCreateBufferFromTransformMat(id<MTLDevice> device, const cv::Mat1f mat);

/// Returns a \c cv::Mat with the contents of the given \c buffer.
cv::Mat1f PNKMatFromBuffer(id<MTLBuffer> buffer);

/// Returns a \c cv::Mat with the contents of the given rgb \c buffer, ignoring the fourth channel
/// padding in the buffer.
cv::Mat3f PNKMatFromRGBBuffer(id<MTLBuffer> buffer);

NS_ASSUME_NONNULL_END
