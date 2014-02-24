// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

using half_float::half;

void LTConvertToSameNumberOfChannels(const cv::Mat &input, cv::Mat *output, int type);
void LTConvertToSameDepth(const cv::Mat &input, cv::Mat *output, int type);

void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type) {
  LTAssert(&input != output, @"Conversion cannot be made in-place");

  // Type is equal -- copy directly to output.
  if (input.type() == type) {
    input.copyTo(*output);
    return;
  }

  BOOL differentDepth = input.depth() != CV_MAT_DEPTH(type);
  BOOL differentChannels = input.channels() != CV_MAT_CN(type);

  cv::Mat sameChannels;

  // Convert channels if needed.
  if (!differentChannels) {
    sameChannels = input;
  } else {
    if (differentDepth) {
      LTConvertToSameNumberOfChannels(input, &sameChannels, type);
    } else {
      LTConvertToSameNumberOfChannels(input, output, type);
      sameChannels = *output;
    }
  }

  // Convert to the correct data type, if needed.
  if (differentDepth) {
    LTConvertToSameDepth(sameChannels, output, type);
  }
}

void LTConvertToSameNumberOfChannels(const cv::Mat &input, cv::Mat *output, int type) {
  // Output will be with the same depth of input, but with correct number of target channels.
  output->create(input.size(), CV_MAKETYPE(input.depth(), CV_MAT_CN(type)));

  Matrices inputs{input};
  Matrices outputs{*output};

  // Add zero matrix if output needs channel padding.
  if (CV_MAT_CN(type) - input.channels() > 0) {
    inputs.push_back(cv::Mat::zeros(input.size(), input.depth()));
  }

  // Formulate fromTo array. Start by copying channels from the input, and move to copy the zero
  // channel if padding is needed.
  std::vector<int> fromTo;
  for (int channel = 0; channel < CV_MAT_CN(type); ++channel) {
    if (channel < input.channels()) {
      fromTo.push_back(channel);
    } else {
      fromTo.push_back(input.channels());
    }
    fromTo.push_back(channel);
  }

  cv::mixChannels(inputs, outputs, &fromTo[0], fromTo.size() / 2);
}

void LTConvertToSameDepth(const cv::Mat &input, cv::Mat *output, int type) {
  if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_16F) {
    LTConvertHalfFloat<float, half>(input, output);
  } else if (input.depth() == CV_16F && CV_MAT_DEPTH(type) == CV_32F) {
    LTConvertHalfFloat<half, float>(input, output);
  } else if (input.depth() == CV_16F && CV_MAT_DEPTH(type) == CV_8U) {
    LTConvertHalfFloat<half, uchar>(input, output, 255);
  } else if (input.depth() == CV_16F || CV_MAT_DEPTH(type) == CV_16F) {
    LTAssert(NO, @"Unsupported half-float conversion: %d to %d", input.depth(), CV_MAT_DEPTH(type));
  } else {
    double alpha = 1;
    if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_8U) {
      alpha = 255;
    } else if (input.depth() == CV_8U && CV_MAT_DEPTH(type) == CV_32F) {
      alpha = 1.0 / 255.0;
    }
    input.convertTo(*output, type, alpha);
  }
}

cv::Mat *LTInPlaceFFTShift(cv::Mat *mat) {
  int rows = mat->rows / 2;
  int cols = mat->cols / 2;

  cv::Mat q0 = (*mat)(cv::Rect(0, 0, rows, cols));
  cv::Mat q1 = (*mat)(cv::Rect(rows, 0, rows, cols));
  cv::Mat q2 = (*mat)(cv::Rect(0, cols, rows, cols));
  cv::Mat q3 = (*mat)(cv::Rect(rows, cols, rows, cols));

  // Shuffle matrix quarters.
  cv::Mat1f temp(rows, cols);
  q0.copyTo(temp);
  q3.copyTo(q0);
  temp.copyTo(q3);
  q1.copyTo(temp);
  q2.copyTo(q1);
  temp.copyTo(q2);

  return mat;
}
