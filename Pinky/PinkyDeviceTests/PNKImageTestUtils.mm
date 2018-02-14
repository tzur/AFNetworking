// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKImageTestUtils.h"

#import <LTEngine/LTOpenCVExtensions.h>

NS_ASSUME_NONNULL_BEGIN

double PNKPsnrScore(const cv::Mat &first, const cv::Mat &second, BOOL ignoreAlphaChannel) {
  LTParameterAssert(first.rows == second.rows, @"first and second matrix rows count must be equal, "
                    "got (%d, %d)", first.rows, second.rows);
  LTParameterAssert(first.cols == second.cols, @"first and second matrix columns count must be "
                    "equal, got (%d, %d)", first.cols, second.cols);
  LTParameterAssert(first.channels() == second.channels(), @"first and second matrix channel count "
                    "must be equal, got (%d, %d)", first.channels(), second.channels());
  LTParameterAssert(!ignoreAlphaChannel || (first.channels() == 4), @"Ignoring alpha channel is "
                    "only possible in images with 4 channels, got %d", first.channels());

  cv::Mat error;
  cv::Mat firstFloat, secondFloat;
  LTConvertMat(first, &firstFloat, CV_32FC(first.channels()));
  LTConvertMat(second, &secondFloat, CV_32FC(second.channels()));

  cv::absdiff(firstFloat, secondFloat, error);
  error = error.mul(error);

  cv::Scalar sumError = cv::sum(error);

  double sse = 0;
  unsigned int channelCount = ignoreAlphaChannel ? 3 : first.channels();
  for (unsigned int i = 0; i < channelCount; ++i) {
    sse += sumError.val[i];
  }

  if (sse <= 1e-10) {
    return INFINITY;
  }
  double mse = sse / (double)(channelCount * first.total());
  return -10.0 * log10(mse);
}

NS_ASSUME_NONNULL_END
