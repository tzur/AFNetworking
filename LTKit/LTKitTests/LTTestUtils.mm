// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

BOOL LTCompareMat(const cv::Mat &a, const cv::Mat &b) {
  if (a.size != b.size || a.depth() != b.depth() || a.channels() != b.channels()) {
    return NO;
  }

  // TODO: (yaron) make this work with other types too.

  for (int y = 0; y < a.rows; ++y) {
    for (int x = 0; x < a.cols; ++x) {
      cv::Vec4b va = a.at<cv::Vec4b>(y, x);
      cv::Vec4b vb = b.at<cv::Vec4b>(y, x);

      if (memcmp(va.val, vb.val, sizeof(va.val))) {
        return NO;
      }
    }
  }

  return YES;
}

cv::Rect LTCVRectWithCGRect(CGRect rect) {
  return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

GLKVector4 LTCVVec4bToGLKVector4(cv::Vec4b value) {
  GLKVector4 result;
  for (int i = 0; i < value.channels; ++i) {
    result.v[i] = value(i) / (float)UCHAR_MAX;
  }
  return result;
}
