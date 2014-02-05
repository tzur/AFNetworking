// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <opencv2/core/core.hpp>

/// Converts the given \c input mat to a \c mat with the given \c type, and writes the result to
/// \c type. The \c output matrix will be created with the corresponding type.
///
/// The following considerations are made while converting:
/// - Number of channels: if the number of channels of \c input is larger than of \c type, the first
///   channels will be used, and the rest will be removed. If the number of channels of \c input is
///   smaller than of \type, zero channels will be appended.
/// - Depth: depth will be converted using \c cv::Mat \c convertTo method. When converting from \c
///   float values to \c ubyte, a scale factor of \c 255 will be used. The inverse scale factor will
///   be used if the inverse conversion direction is requested.
///
/// If \c type is equal to \c input.type(), the data will be copied directly to the output.
void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type);
