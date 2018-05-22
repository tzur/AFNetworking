// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKImageMotionLayerUtils.h"

NS_ASSUME_NONNULL_BEGIN

void PNKImageMotionValidateDisplacementsMatrix(const cv::Mat &displacements,
                                               cv::Size expectedSize) {
  LTParameterAssert(displacements.size() == expectedSize, @"Displacements matrix should be of size "
                    "(%d, %d), got (%d, %d)", expectedSize.height, expectedSize.width,
                    displacements.rows, displacements.cols);
  LTParameterAssert(displacements.channels() == 2, @"Displacements matrix should have 2 channels, "
                    "got %d", displacements.channels());
  LTParameterAssert(displacements.depth() == CV_16F, @"Displacements matrix should be of "
                    "half-float type (%d), got %d", CV_16F, displacements.depth());
}

NS_ASSUME_NONNULL_END
