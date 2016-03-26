// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

/// Category for boxing and unboxing the \c cv::Mat type.
@interface NSValue (OpenCVExtensions)

/// Returns an unboxed \c cv::Mat value.
- (const cv::Mat &)matValue;

/// Returns an unboxed \c cv::Scalar value.
- (cv::Scalar)scalarValue;

/// Boxes \c cv::Mat as \c NSValue.
+ (NSValue *)valueWithMat:(const cv::Mat &)mat;

/// Boxes \c cv::Scalar as \c NSValue.
+ (NSValue *)valueWithScalar:(const cv::Scalar &)scalar;

@end
