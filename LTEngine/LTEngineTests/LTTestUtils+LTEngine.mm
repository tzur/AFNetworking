// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils+LTEngine.h"

#import <LTKit/LTEnumRegistry.h>
#import <LTKit/UIDevice+Hardware.h>
#import <Specta/SpectaDSL.h>
#import <Specta/SpectaUtility.h>

#import "LTImage.h"
#import "LTOpenCVExtensions.h"

using half_float::half;

#pragma mark -
#pragma mark Forward declarations
#pragma mark -

static cv::Vec4hf LTScalarToHalfFloat(const cv::Scalar &scalar);
static NSString *LTHalfFloatMatAsString(const cv::Mat &mat, cv::Point position);

static BOOL LTCompareMatMetadata(const cv::Mat &expected, const cv::Mat &actual);

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual, const T &fuzziness,
                              cv::Point *firstMismatch);

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

cv::Mat LTRotateMat(const cv::Mat input, CGFloat angle) {
  angle = angle * (-180 / M_PI);
  cv::Point2f center((input.cols / 2.0) - 0.5, (input.rows / 2.0) - 0.5);
  cv::Mat R = cv::getRotationMatrix2D(center, angle, 1.0);
  cv::Mat rotated;
  cv::warpAffine(input, rotated, R, input.size(), cv::INTER_NEAREST, cv::BORDER_REPLICATE);
  return rotated;
}

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual, cv::Point *firstMismatch) {
  if (LTCompareMatMetadata(expected, actual)) {
    LTWriteMatrices(expected, actual);
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual, 0, firstMismatch);
    case CV_8UC2:
      return LTCompareMatCells<cv::Vec2b>(expected, actual, 0, firstMismatch);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual, cv::Vec4b(0, 0, 0, 0), firstMismatch);
    case CV_16F:
      return LTCompareMatCells<half>(expected, actual, half(0.f), firstMismatch);
    case CV_16FC2:
      return LTCompareMatCells<cv::Vec2hf>(expected, actual, cv::Vec2hf(half(0.f), half(0.f)),
                                           firstMismatch);
    case CV_16FC4:
      return LTCompareMatCells<cv::Vec4hf>(expected, actual, cv::Vec4hf(half(0.f), half(0.f),
                                                                        half(0.f), half(0.f)),
                                           firstMismatch);
    case CV_32F:
      return LTCompareMatCells<float>(expected, actual, 0.f, firstMismatch);
    case CV_32FC4:
      return LTCompareMatCells<cv::Vec4f>(expected, actual, cv::Vec4f(0, 0, 0, 0), firstMismatch);
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range,
                       cv::Point *firstMismatch) {
  if (LTCompareMatMetadata(expected, actual)) {
    LTWriteMatrices(expected, actual);
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual, range, firstMismatch);
    case CV_8UC2:
      return LTCompareMatCells<cv::Vec2b>(expected, actual, cv::Vec2b(range, range), firstMismatch);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual, cv::Vec4b(range, range, range, range),
                                          firstMismatch);
    case CV_16FC1:
      return LTCompareMatCells<half>(expected, actual, half(range), firstMismatch);
    case CV_16FC2:
      return LTCompareMatCells<cv::Vec2hf>(expected, actual, cv::Vec2hf(half(range), half(range)),
                                           firstMismatch);
    case CV_16FC4:
      return LTCompareMatCells<cv::Vec4hf>(expected, actual, cv::Vec4hf(half(range), half(range),
                                                                        half(range), half(range)),
                                           firstMismatch);
    case CV_32F:
      return LTCompareMatCells<float>(expected, actual, range, firstMismatch);
    case CV_32FC4:
      return LTCompareMatCells<cv::Vec4f>(expected, actual, cv::Vec4f(range, range, range, range),
                                          firstMismatch);
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                           cv::Point *firstMismatch) {
  cv::Mat mat(actual.rows, actual.cols, actual.type());
  mat.setTo(expected);
  return LTCompareMat(mat, actual, firstMismatch);
}

BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual, double range,
                                cv::Point *firstMismatch) {
  cv::Mat mat(actual.rows, actual.cols, actual.type());
  if (mat.depth() == CV_16F) {
    mat.setTo(LTScalarToHalfFloat(expected));
  } else {
    mat.setTo(expected);
  }
  return LTFuzzyCompareMat(mat, actual, range, firstMismatch);
}

static cv::Vec4hf LTScalarToHalfFloat(const cv::Scalar &scalar) {
  return cv::Vec4hf(half(scalar[0]), half(scalar[1]), half(scalar[2]), half(scalar[3]));
}

NSString *LTMatValueAsString(const cv::Mat &mat, cv::Point position) {
  if (mat.depth() == CV_16F) {
    return LTHalfFloatMatAsString(mat, position);
  } else {
    std::stringstream message;
    message << mat(cv::Rect(position, cv::Size(1, 1)));
    return [NSString stringWithCString:message.str().c_str() encoding:NSUTF8StringEncoding];
  }
}

static NSString *LTHalfFloatMatAsString(const cv::Mat &mat, cv::Point position) {
  switch (mat.channels()) {
    case 1: {
      half value(mat.at<half>(position));
      return [NSString stringWithFormat:@"[%g]", (float)value];
    } case 2: {
      cv::Vec2hf value(mat.at<cv::Vec2hf>(position));
      return [NSString stringWithFormat:@"[%g, %g]", (float)value[0], (float)value[1]];
    } case 3: {
      cv::Vec3hf value(mat.at<cv::Vec3hf>(position));
      return [NSString stringWithFormat:@"[%g, %g, %g]", (float)value[0], (float)value[1],
              (float)value[2]];
    } case 4: {
      cv::Vec4hf value(mat.at<cv::Vec4hf>(position));
      return [NSString stringWithFormat:@"[%g, %g, %g, %g]", (float)value[0], (float)value[1],
              (float)value[2], (float)value[3]];
    } default:
      return @"[Invalid number of channels]";
  }
}

NSString *LTScalarAsString(const cv::Scalar &scalar) {
  return [NSString stringWithFormat:@"[%g, %g, %g, %g]",
          scalar[0], scalar[1], scalar[2], scalar[3]];
}

LTVector4 LTBlendNormal(const LTVector4 &src, const LTVector4 &dst) {
  CGFloat a = src.a() + dst.a() - src.a() * dst.a();
  LTVector3 rgb = src.rgb() + dst.rgb() * (1 - src.a());
  return LTVector4(rgb, a);
}

LTVector4 LTBlendMultiply(const LTVector4 &src, const LTVector4 &dst) {
  CGFloat a = src.a() + dst.a() - src.a() * dst.a();
  LTVector3 rgb = src.rgb() * dst.rgb() + src.rgb() * (1 - dst.a()) + dst.rgb() * (1 - src.a());
  return LTVector4(rgb, a);
}

cv::Vec4b LTBlend(const cv::Vec4b &oldColor, const cv::Vec4b &newColor, bool premultiplied,
                  LTBlendMode mode) {
  LTVector4 src = LTCVVec4bToLTVector4(newColor);
  LTVector4 dst = LTCVVec4bToLTVector4(oldColor);
  LTVector4 blended;
  if (!premultiplied) {
    src = LTVector4(src.rgb() * src.a(), src.a());
    dst = LTVector4(dst.rgb() * dst.a(), dst.a());
  }
  switch (mode) {
    case LTBlendModeNormal:
      blended = LTBlendNormal(src, dst);
      break;
    case LTBlendModeMultiply:
      blended = LTBlendMultiply(src, dst);
      break;
    default:
      LTMethodNotImplemented();
  }
  if (!premultiplied) {
    blended = blended.a() > 0 ? LTVector4(blended.rgb() / blended.a(), blended.a()) : LTVector4Zero;
  }
  blended = std::round(blended * UCHAR_MAX) / UCHAR_MAX;
  return LTLTVector4ToVec4b(blended);
}

cv::Rect LTCVRectWithCGRect(CGRect rect) {
  return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

LTVector4 LTCVVec4bToLTVector4(cv::Vec4b value) {
  LTVector4 result;
  for (int i = 0; i < value.channels; ++i) {
    result.data()[i] = value(i) / (float)UCHAR_MAX;
  }
  return result;
}

LTVector4 LTCVVec4hfToLTVector4(cv::Vec4hf value) {
  LTVector4 result;
  for (int i = 0; i < value.channels; ++i) {
    result.data()[i] = (float)value(i);
  }
  return result;
}

cv::Vec4b LTLTVector4ToVec4b(LTVector4 value) {
  return (cv::Vec4b)value;
}

cv::Mat4b LTCreateDeltaMat(CGSize size, CGPoint position) {
  LTParameterAssert(position.x >= 0 && position.y >= 0 && position.x < size.width &&
                    position.y < size.height, @"Position should be bounded by size");
  cv::Mat4b delta(size.height, size.width);
  delta = cv::Vec4b(0, 0, 0, 255);
  delta(position.y, position.x) = cv::Vec4b(255, 255, 255, 255);
  return delta;
}

cv::Mat4b LTCreateDeltaMat(CGSize size) {
  CGSize middle = std::floor(size / 2);
  return LTCreateDeltaMat(size, CGPointMake(middle.width, middle.height));
}

UIImage *LTCreateUIImage(CGSize size) {
  UIGraphicsBeginImageContext(size);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

cv::Mat LTLoadDeviceDependentMat(Class classInBundle, NSString *simulatorName,
                                 NSString *deviceName) {
  cv::Mat mat;
  if ([UIDevice currentDevice].lt_deviceKind == UIDeviceKindSimulatorIPhone ||
      [UIDevice currentDevice].lt_deviceKind == UIDeviceKindSimulatorIPad) {
    mat = LTLoadMat(classInBundle, simulatorName);
  } else {
    mat = LTLoadMat(classInBundle, deviceName);
  }
  return mat;
}

#pragma mark -
#pragma mark Implementation
#pragma mark -

static BOOL LTCompareMatMetadata(const cv::Mat &expected, const cv::Mat &actual) {
  return expected.size != actual.size || expected.depth() != actual.depth() ||
      expected.channels() != actual.channels();
}

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual, const T &fuzziness,
                              cv::Point *firstMismatch) {
  for (int y = 0; y < expected.rows; ++y) {
    for (int x = 0; x < expected.cols; ++x) {
      T va = expected.at<T>(y, x);
      T vb = actual.at<T>(y, x);

      if (!LTCompareMatCell(va, vb, fuzziness, std::is_fundamental<T>())) {
        LTWriteMatrices(expected, actual);
        if (firstMismatch) {
          *firstMismatch = cv::Point(x, y);
        }
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
    for (int i = 0; i < cv::DataType<T>::channels; ++i) {
      typename cv::DataType<T>::channel_type diff =
          expected[i] > actual[i] ? expected[i] - actual[i] : actual[i] - expected[i];
      if (diff > fuzziness[i]) {
        return NO;
      }
    }
    return YES;
  }
}

template <>
inline BOOL LTCompareMatCell(const half &expected, const half &actual, const half &fuzziness,
                                    const std::false_type __unused &isFundamental) {
  return std::abs(expected - actual) <= fuzziness;
}

static void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  static NSMutableDictionary *testCaseCallCount = [NSMutableDictionary dictionary];

  NSString *testCase = [SPTCurrentSpec description];
  testCaseCallCount[testCase] = @([testCaseCallCount[testCase] unsignedIntegerValue] + 1);
  NSUInteger index = [testCaseCallCount[testCase] unsignedIntegerValue];

  LTWriteMat(expected, LTMatPathForNameAndIndex(@"expected", index));
  LTWriteMat(actual, LTMatPathForNameAndIndex(@"actual", index));
}

static NSString *LTMatPathForNameAndIndex(NSString *name, NSUInteger index) {
  static NSString * const kMatOutputBasedir = @"/tmp/";

  NSString *filename = [NSString stringWithFormat:@"%@-%lu-%@.png",
                        [SPTCurrentSpec description], (unsigned long)index, name];

  return [kMatOutputBasedir stringByAppendingPathComponent:filename];
}

static void LTWriteMat(const cv::Mat &mat, NSString *path) {
  switch (mat.type()) {
    case CV_8UC1:
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], mat);
      break;
    case CV_8UC2: {
      cv::Mat ones = cv::Mat::ones(mat.rows, mat.cols, CV_8U) * 255;
      cv::Mat zeros = cv::Mat::zeros(mat.rows, mat.cols, CV_8U);
      cv::Mat paddedMat(mat.rows, mat.cols, CV_8UC4);
      const int fromTo[] = {0, 2, 1, 1, 2, 0, 3, 3};
      Matrices inputs{mat, zeros, ones};
      Matrices outputs{paddedMat};
      cv::mixChannels(inputs, outputs, fromTo, 4);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], paddedMat);
    } break;
    case CV_8UC4: {
      cv::Mat bgrMat;
      cv::cvtColor(mat, bgrMat, CV_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_16F:
    case CV_16FC4: {
      cv::Mat4b converted;
      LTConvertMat(mat, &converted, converted.type());
      cv::Mat bgrMat;
      cv::cvtColor(converted, bgrMat, CV_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_32F: {
      cv::Mat converted;
      mat.convertTo(converted, CV_8U, 255.0);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], converted);
    } break;
    case CV_32FC4: {
      cv::Mat converted;
      mat.convertTo(converted, CV_8UC4, 255.0);
      cv::Mat bgrMat;
      cv::cvtColor(converted, bgrMat, CV_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    default:
      LTAssert(NO, @"Unsupported mat type given: %d", mat.type());
  }
}
