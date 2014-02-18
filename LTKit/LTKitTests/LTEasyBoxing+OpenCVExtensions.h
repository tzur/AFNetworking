// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSValue+OpenCVExtensions.h"

NS_INLINE NSValue *$(const cv::Mat &value) { \
  return [NSValue valueWithMat:value]; \
}

NS_INLINE NSValue *$(const cv::Scalar &value) { \
  return [NSValue valueWithScalar:value]; \
}
