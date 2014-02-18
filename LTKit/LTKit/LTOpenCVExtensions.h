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

/// Converts the given \c input mat to an \c output mat with an optional \c alpha scaling. Either \c
/// input or \c output should be of half-float precision. The \c _From and \c _To template
/// parameters define the source matrix type and the target matrix type to convert to, accordingly.
template <typename _From, typename _To>
void LTConvertHalfFloat(const cv::Mat &input, cv::Mat *output, double alpha = 1);

#pragma mark -
#pragma mark Details
#pragma mark -

template <typename _From, typename _To>
void LTConvertHalfFloat(const cv::Mat &input, cv::Mat *output, double alpha) {
  static_assert(cv::DataDepth<_From>::value == CV_16F ||
                cv::DataDepth<_To>::value == CV_16F, "_From or _To must be of a half-float type");

  output->create(input.size(), CV_MAKETYPE(cv::DataDepth<_To>::value, input.channels()));
  LTAssert(input.isContinuous() && output->isContinuous(), @"input and output matrices must be "
           "continuous for this conversion operation");

  // TODO:(yaron) performance can be increased by doing this in batch.
  _From *inputData = (_From *)input.data;
  _To *outputData = (_To *)output->data;
  for (size_t i = 0; i < input.total() * input.channels(); ++i) {
    outputData[i] = cv::saturate_cast<_To>(half_float::half(inputData[i]) * alpha);
  }
}
