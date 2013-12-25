// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import "SpectaUtility.h"

static NSString * const kMatOutputBasedir = @"/tmp/";

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual);
static void LTWriteMat(const cv::Mat &mat, NSString *name);

#pragma mark -
#pragma mark Public methods
#pragma mark -

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual) {
  if (expected.size != actual.size || expected.depth() != actual.depth() ||
      expected.channels() != actual.channels()) {
    return NO;
  }

  // TODO: (yaron) make this work with other types too.

  for (int y = 0; y < expected.rows; ++y) {
    for (int x = 0; x < expected.cols; ++x) {
      cv::Vec4b va = expected.at<cv::Vec4b>(y, x);
      cv::Vec4b vb = actual.at<cv::Vec4b>(y, x);

      if (memcmp(va.val, vb.val, sizeof(va.val))) {
        LTWriteMatrices(expected, actual);
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

cv::Vec4b LTGLKVector4ToVec4b(GLKVector4 value) {
  return cv::Vec4b(value.x * UCHAR_MAX, value.y * UCHAR_MAX,
                   value.z * UCHAR_MAX, value.w * UCHAR_MAX);
}

#pragma mark -
#pragma mark Implementation
#pragma mark -

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  LTWriteMat(expected, @"expected");
  LTWriteMat(actual, @"actual");
}

static void LTWriteMat(const cv::Mat &mat, NSString *name) {
  NSString *filename = [NSString stringWithFormat:@"%@-%@.png",
                        [SPTCurrentTestCase description], name];
  NSString *path = [kMatOutputBasedir stringByAppendingPathComponent:filename];
  cv::Mat bgrMat;
  cv::cvtColor(mat, bgrMat, CV_RGBA2BGRA);
  cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
}
