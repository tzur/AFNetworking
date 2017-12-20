// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "PNKColorTransferTestUtils.h"

#import <LTEngine/NSValue+LTVector.h>

NS_ASSUME_NONNULL_BEGIN

id<MTLBuffer> PNKCreateBufferFromMat(id<MTLDevice> device, const cv::Mat3f mat) {
  auto buffer = [device newBufferWithLength:mat.total() * 4 * sizeof(float)
                                    options:MTLResourceStorageModeShared];
  for (NSUInteger i = 0; i < mat.total(); ++i) {
    cv::Vec3f element = *(mat.begin() + i);
    ((float *)buffer.contents + 4 * i)[0] = element[0];
    ((float *)buffer.contents + 4 * i)[1] = element[1];
    ((float *)buffer.contents + 4 * i)[2] = element[2];
  }

  return buffer;
}

id<MTLBuffer> PNKCreateBufferFromTransformMat(id<MTLDevice> device, const cv::Mat1f mat) {
  LTParameterAssert(mat.rows == 3 && mat.cols == 3);
  auto buffer = [device newBufferWithLength:12 * sizeof(float)
                                    options:MTLResourceStorageModeShared];

  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 4; ++j) {
      ((float *)buffer.contents + i * 4)[j] = j < 3 ? mat(j, i) : 0;
    }
  }

  return buffer;
}

cv::Mat1f PNKMatFromBuffer(id<MTLBuffer> buffer) {
  cv::Mat1f mat(1, (int)buffer.length / sizeof(float), (float *)buffer.contents);
  return mat.clone();
}

cv::Mat3f PNKMatFromRGBBuffer(id<MTLBuffer> buffer) {
  cv::Mat4f matRGBA = cv::Mat(1, (int)buffer.length / sizeof(float) / 4, CV_32FC4, buffer.contents);
  std::vector<cv::Mat1f> channels;
  cv::split(matRGBA, channels);
  channels.pop_back();

  cv::Mat3f matRGB;
  cv::merge(channels, matRGB);
  return matRGB;
}

NS_ASSUME_NONNULL_END
