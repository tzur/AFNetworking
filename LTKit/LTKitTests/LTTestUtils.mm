// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import "SpectaUtility.h"

static NSString * const kMatOutputBasedir = @"/tmp/";

#pragma mark -
#pragma mark Forward declarations
#pragma mark -

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual,
                                    const std::true_type &isFundamental);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual,
                                    const std::false_type &isFundamental);

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual);
static void LTWriteMat(const cv::Mat &mat, NSString *name);
static NSString *LTMatPathForName(NSString *name);

#pragma mark -
#pragma mark Public methods
#pragma mark -

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual) {
  if (expected.size != actual.size || expected.depth() != actual.depth() ||
      expected.channels() != actual.channels()) {
    LTWriteMatrices(expected, actual);
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual);
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
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

UIImage *LTLoadImageWithName(Class classInBundle, NSString *name) {
  NSString *path = LTPathForResource(classInBundle, name);
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  LTAssert(image, @"Image cannot be loaded");

  return image;
}

NSString *LTPathForResource(Class classInBundle, NSString *name) {
  NSBundle *bundle = [NSBundle bundleForClass:classInBundle];

  NSString *resource = [name stringByDeletingPathExtension];
  NSString *type = [name pathExtension];

  NSString *path = [bundle pathForResource:resource ofType:type];
  LTAssert(path, @"Given image filename doesn't exist in the test bundle");

  return path;
}

#pragma mark -
#pragma mark Implementation
#pragma mark -

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual) {
  for (int y = 0; y < expected.rows; ++y) {
    for (int x = 0; x < expected.cols; ++x) {
      T va = expected.at<T>(y, x);
      T vb = actual.at<T>(y, x);

      if (!LTCompareMatCell(va, vb, std::is_fundamental<T>())) {
        LTWriteMatrices(expected, actual);
        return NO;
      }
    }
  }

  return YES;
}

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual,
                                    const std::true_type __unused &isFundamental) {
  return expected == actual;
}

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual,
                                    const std::false_type __unused &isFundamental) {
  return !memcmp(expected.val, actual.val, sizeof(expected.val));
}

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  LTWriteMat(expected, LTMatPathForName(@"expected"));
  LTWriteMat(actual, LTMatPathForName(@"actual"));
}

static NSString *LTMatPathForName(NSString *name) {
  NSString *filename = [NSString stringWithFormat:@"%@-%@.png",
                        [SPTCurrentTestCase description], name];
  return [kMatOutputBasedir stringByAppendingPathComponent:filename];
}

static void LTWriteMat(const cv::Mat &mat, NSString *path) {
  switch (mat.type()) {
    case CV_8UC4: {
      cv::Mat bgrMat;
      cv::cvtColor(mat, bgrMat, CV_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_8UC1:
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], mat);
      break;
    default:
      LTAssert(NO, @"Unsupported mat type given: %d", mat.type());
  }
}
