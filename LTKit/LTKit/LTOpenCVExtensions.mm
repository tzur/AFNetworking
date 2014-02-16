// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

using half_float::half;

void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type) {
  LTAssert(&input != output, @"Conversion cannot be made in-place");

  // Type is equal -- copy directly to output.
  if (input.type() == type) {
    input.copyTo(*output);
    return;
  }

  const cv::Mat *sameChannels;

  // Convert channels if needed.
  if (input.channels() == CV_MAT_CN(type)) {
    sameChannels = &input;
  } else {
    // Output will be with the same depth of input, but with correct number of target channels.
    output->create(input.rows, input.cols, CV_MAKETYPE(input.depth(), CV_MAT_CN(type)));

    Matrices inputs{input};
    Matrices outputs{*output};

    // Add zero matrix if output needs channel padding.
    if (CV_MAT_CN(type) - input.channels() > 0) {
      inputs.push_back(cv::Mat::zeros(input.rows, input.cols, input.depth()));
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

    sameChannels = output;
  }

  // Convert to the correct data type, if needed.
  if (input.depth() != CV_MAT_DEPTH(type)) {
    if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_16F) {
      LTConvertHalfFloat<float, half>(*sameChannels, output);
    } else if (input.depth() == CV_16F && CV_MAT_DEPTH(type) == CV_32F) {
      LTConvertHalfFloat<half, float>(*sameChannels, output);
    } else if (input.depth() == CV_16F || CV_MAT_DEPTH(type) == CV_16F) {
      LTAssert(NO, @"Converting from/to half-float to non-float types is not yet supported");
    } else {
      double alpha = 1;
      if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_8U) {
        alpha = 255;
      } else if (input.depth() == CV_8U && CV_MAT_DEPTH(type) == CV_32F) {
        alpha = 1.0 / 255.0;
      }
      sameChannels->convertTo(*output, type, alpha);
    }
  }
}
