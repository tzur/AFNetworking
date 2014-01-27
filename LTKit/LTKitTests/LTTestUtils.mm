// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import "LTCGExtensions.h"
#import "LTImage.h"
#import "SpectaUtility.h"

static NSString * const kMatOutputBasedir = @"/tmp/";

#pragma mark -
#pragma mark Forward declarations
#pragma mark -

static BOOL LTCompareMatMetadata(const cv::Mat &expected, const cv::Mat &actual);

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual, const T &fuzziness);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::true_type &isFundamental);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::false_type &isFundamental);

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual);
static void LTWriteMat(const cv::Mat &mat, NSString *name);
static NSString *LTMatPathForNameAndIndex(NSString *name, NSUInteger index);

#pragma mark -
#pragma mark Public methods
#pragma mark -

void sit(NSString __unused *name, id __unused block) {
#if TARGET_IPHONE_SIMULATOR
  it(name, block);
#endif
}

void dit(NSString __unused *name, id __unused block) {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
  it(name, block);
#endif
}

BOOL LTRunningApplicationTests() {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  return environment[@"XCInjectBundle"] != nil;
}

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual) {
  if (LTCompareMatMetadata(expected, actual)) {
    LTWriteMatrices(expected, actual);
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual, 0);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual, cv::Vec4b(0, 0, 0, 0));
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range) {
  if (LTCompareMatMetadata(expected, actual)) {
    LTWriteMatrices(expected, actual);
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual, range);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual, cv::Vec4b(range, range, range, range));
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual) {
  cv::Mat mat(actual.rows, actual.cols, actual.type());
  mat.setTo(expected);
  return LTCompareMat(mat, actual);
}

BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual, double range) {
  cv::Mat mat(actual.rows, actual.cols, actual.type());
  mat.setTo(expected);
  return LTFuzzyCompareMat(mat, actual, range);
}

cv::Vec4b LTBlend(const cv::Vec4b &oldColor, const cv::Vec4b &newColor) {
  static const CGFloat inv = 1.0 / UCHAR_MAX;
  cv::Vec4b blended;
  cv::Vec4b blendedAlpha;
  cv::addWeighted(oldColor, 1 - inv * newColor[3], newColor, 1, 0, blended);
  cv::addWeighted(oldColor, 1, newColor, 1 - inv * oldColor[3], 0, blendedAlpha);
  blended[3] = blendedAlpha[3];
  return blended;
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

cv::Mat4b delta(CGSize size) {
  cv::Mat4b delta(size.width, size.height);
  delta = cv::Vec4b(0, 0, 0, 255);
  CGSize middle = std::floor(size / 2);
  delta(middle.width, middle.height) = cv::Vec4b(255, 255, 255, 255);
  return delta;
}

UIImage *LTLoadImageWithName(Class classInBundle, NSString *name) {
  NSString *path = LTPathForResource(classInBundle, name);
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  LTAssert(image, @"Image cannot be loaded");

  return image;
}

cv::Mat LTLoadMatWithName(Class classInBundle, NSString *name) {
  UIImage *image = LTLoadImageWithName(classInBundle, name);
  return [[LTImage alloc] initWithImage:image].mat;
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

static BOOL LTCompareMatMetadata(const cv::Mat &expected, const cv::Mat &actual) {
  return expected.size != actual.size || expected.depth() != actual.depth() ||
      expected.channels() != actual.channels();
}

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual, const T &fuzziness) {
  for (int y = 0; y < expected.rows; ++y) {
    for (int x = 0; x < expected.cols; ++x) {
      T va = expected.at<T>(y, x);
      T vb = actual.at<T>(y, x);

      if (!LTCompareMatCell(va, vb, fuzziness, std::is_fundamental<T>())) {
        LTWriteMatrices(expected, actual);
        return NO;
      }
    }
  }

  return YES;
}

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::true_type __unused &isFundamental) {
  return expected == actual || std::abs(expected - actual) <= fuzziness;
}

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::false_type __unused &isFundamental) {
  if (!memcmp(expected.val, actual.val, sizeof(expected.val))) {
    return YES;
  } else {
    T diff;
    cv::absdiff(expected, actual, diff);
    return cv::norm(diff, cv::NORM_L1) < cv::norm(fuzziness, cv::NORM_L1);
  }
}

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  static NSMutableDictionary *testCaseCallCount = [NSMutableDictionary dictionary];

  NSString *testCase = [SPTCurrentTestCase description];
  testCaseCallCount[testCase] = @([testCaseCallCount[testCase] unsignedIntegerValue] + 1);
  NSUInteger index = [testCaseCallCount[testCase] unsignedIntegerValue];

  LTWriteMat(expected, LTMatPathForNameAndIndex(@"expected", index));
  LTWriteMat(actual, LTMatPathForNameAndIndex(@"actual", index));
}

static NSString *LTMatPathForNameAndIndex(NSString *name, NSUInteger index) {
  NSString *filename = [NSString stringWithFormat:@"%@-%lu-%@.png",
                        [SPTCurrentTestCase description], (unsigned long)index, name];

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
