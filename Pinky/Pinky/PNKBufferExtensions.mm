// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKBufferExtensions.h"

#import <LTEngine/LTOpenCVExtensions.h>

NS_ASSUME_NONNULL_BEGIN

NSUInteger PNKImageAlignedBufferElementsFromMatrix(const cv::Mat &matrix) {
  static const NSUInteger kChannelsPerTexture = 4;
  int elementsCount = matrix.cols * matrix.rows;
  return ((elementsCount + kChannelsPerTexture - 1) / kChannelsPerTexture) * kChannelsPerTexture;
}

void PNKFillHalfFloatBuffer(id<MTLBuffer> buffer, const cv::Mat &parameters) {
  LTParameterAssert(parameters.isContinuous(), @"Parameter matrix must be continuous");
  LTParameterAssert(parameters.type() == CV_32FC1 || parameters.type() == CV_16FC1, @"Supported "
                    "parameter types are cv::Mat1f (%d) and cv::Mat1hf (%d), got %d",
                    CV_32FC1, CV_16FC1, parameters.type());
  int elementsCount = parameters.cols * parameters.rows;
  LTParameterAssert(buffer.length >= elementsCount * sizeof(half_float::half),
                    @"Buffer size must be %lu, got %lu",
                    (unsigned long)elementsCount * sizeof(half_float::half),
                    (unsigned long)buffer.length);
  cv::Mat bufferMat(parameters.rows, parameters.cols, CV_16F, buffer.contents);
  LTConvertMat(parameters, &bufferMat, CV_16FC1);
}

id<MTLBuffer> PNKHalfBufferFromFloatVector(id<MTLDevice> device, const cv::Mat1f &parameters) {
  NSUInteger bufferElements = parameters.total();
  id<MTLBuffer> buffer = [device newBufferWithLength:bufferElements * sizeof(half_float::half)
                                             options:MTLResourceCPUCacheModeWriteCombined];
  PNKFillHalfFloatBuffer(buffer, parameters);
  return buffer;
}

NS_ASSUME_NONNULL_END
