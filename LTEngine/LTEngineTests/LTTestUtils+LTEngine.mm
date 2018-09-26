// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils+LTEngine.h"

#import <LTEngine/LTImage.h>
#import <LTEngine/LTOpenCVExtensions.h>
#import <LTKit/LTRandom.h>
#import <LTKit/UIDevice+Hardware.h>
#import <Specta/SpectaDSL.h>
#import <Specta/SpectaUtility.h>
#import <opencv2/imgcodecs.hpp>

using half_float::half;

#pragma mark -
#pragma mark Forward declarations
#pragma mark -

static cv::Vec4hf LTScalarToHalfFloat(const cv::Scalar &scalar);

template <typename T>
static NSString *LTMatAsString(const cv::Mat &mat, const std::vector<int> &position);

static NSString *LTHalfFloatMatAsString(const cv::Mat &mat, const std::vector<int> &position);

static BOOL LTCompareMatMetadata(const cv::Mat &expected, const cv::Mat &actual);

template <typename T>
static BOOL LTCompareMatCells(const cv::Mat &expected, const cv::Mat &actual, const T &fuzziness,
                              std::vector<int> *firstMismatch);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::true_type &isFundamental);

template <typename T>
static inline BOOL LTCompareMatCell(const T &expected, const T &actual, const T &fuzziness,
                                    const std::false_type &isFundamental);

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

BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual, std::vector<int> *firstMismatch) {
  if (LTCompareMatMetadata(expected, actual)) {
    return NO;
  }

  switch (expected.type()) {
    case CV_8UC1:
      return LTCompareMatCells<uchar>(expected, actual, 0, firstMismatch);
    case CV_8UC2:
      return LTCompareMatCells<cv::Vec2b>(expected, actual, 0, firstMismatch);
    case CV_8UC3:
      return LTCompareMatCells<cv::Vec3b>(expected, actual, 0, firstMismatch);
    case CV_8UC4:
      return LTCompareMatCells<cv::Vec4b>(expected, actual, cv::Vec4b(0, 0, 0, 0), firstMismatch);
    case CV_16UC4:
      return LTCompareMatCells<cv::Vec4w>(expected, actual, cv::Vec4w(0, 0, 0, 0), firstMismatch);
    case CV_16F:
      return LTCompareMatCells<half>(expected, actual, half(0.f), firstMismatch);
    case CV_16FC2:
      return LTCompareMatCells<cv::Vec2hf>(expected, actual, cv::Vec2hf(half(0.f), half(0.f)),
                                           firstMismatch);
    case CV_16FC4:
      return LTCompareMatCells<cv::Vec4hf>(expected, actual, cv::Vec4hf(half(0.f), half(0.f),
                                                                        half(0.f), half(0.f)),
                                           firstMismatch);
    case CV_16U:
      return LTCompareMatCells<ushort>(expected, actual, 0, firstMismatch);
    case CV_32S:
      return LTCompareMatCells<int>(expected, actual, 0, firstMismatch);
    case CV_32SC2:
      return LTCompareMatCells<cv::Vec2i>(expected, actual, 0, firstMismatch);
    case CV_32F:
      return LTCompareMatCells<float>(expected, actual, 0.f, firstMismatch);
    case CV_32FC4:
      return LTCompareMatCells<cv::Vec4f>(expected, actual, cv::Vec4f(0, 0, 0, 0), firstMismatch);
    case CV_64F:
      return LTCompareMatCells<double>(expected, actual, 0.f, firstMismatch);
    case CV_64FC4:
      return LTCompareMatCells<cv::Vec4d>(expected, actual, cv::Vec4d(0, 0, 0, 0), firstMismatch);
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range,
                       std::vector<int> *firstMismatch) {
  if (LTCompareMatMetadata(expected, actual)) {
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
    case CV_16U:
      return LTCompareMatCells<ushort>(expected, actual, range, firstMismatch);
    case CV_16UC4:
      return LTCompareMatCells<cv::Vec4w>(expected, actual, cv::Vec4w(range, range, range, range),
                                          firstMismatch);
    case CV_32S:
      return LTCompareMatCells<int>(expected, actual, range, firstMismatch);
    case CV_32SC2:
      return LTCompareMatCells<cv::Vec2i>(expected, actual, range, firstMismatch);
    case CV_32F:
      return LTCompareMatCells<float>(expected, actual, range, firstMismatch);
    case CV_32FC3:
      return LTCompareMatCells<cv::Vec3f>(expected, actual, cv::Vec3f(range, range, range),
                                          firstMismatch);
    case CV_32FC4:
      return LTCompareMatCells<cv::Vec4f>(expected, actual, cv::Vec4f(range, range, range, range),
                                          firstMismatch);
    case CV_64F:
      return LTCompareMatCells<double>(expected, actual, range, firstMismatch);
    case CV_64FC4:
      return LTCompareMatCells<cv::Vec4d>(expected, actual, cv::Vec4d(range, range, range, range),
                                          firstMismatch);
    default:
      LTAssert(NO, @"Unsupported mat type for comparison: %d", expected.type());
  }
}

BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                           std::vector<int> *firstMismatch) {
  cv::Mat mat(actual.rows, actual.cols, actual.type());
  mat.setTo(expected);
  return LTCompareMat(mat, actual, firstMismatch);
}

BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual, double range,
                                std::vector<int> *firstMismatch) {
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

NSString *LTIndicesVectorAsString(const std::vector<int> &indices) {
  LTParameterAssert(indices.size(), @"indices vector cannot be empty");

  std::stringstream stream;
  stream << "(";
  std::copy(indices.cbegin(), indices.cend() - 1, std::ostream_iterator<int>(stream, ","));
  stream << indices.back() << ")";
  return [NSString stringWithUTF8String:stream.str().c_str()];
}

NSString *LTMatValueAsString(const cv::Mat &mat, const std::vector<int> &position) {
  switch (mat.type()) {
    case CV_8UC1:
      return LTMatAsString<uchar>(mat, position);
    case CV_8UC2:
      return LTMatAsString<cv::Vec2b>(mat, position);
    case CV_8UC3:
      return LTMatAsString<cv::Vec3b>(mat, position);
    case CV_8UC4:
      return LTMatAsString<cv::Vec4b>(mat, position);
    case CV_16UC4:
      return LTMatAsString<cv::Vec4w>(mat, position);
    case CV_16FC1:
    case CV_16FC2:
    case CV_16FC4:
      return LTHalfFloatMatAsString(mat, position);
    case CV_16U:
      return LTMatAsString<ushort>(mat, position);
    case CV_32S:
      return LTMatAsString<int>(mat, position);
    case CV_32SC2:
      return LTMatAsString<cv::Vec2i>(mat, position);
    case CV_32F:
      return LTMatAsString<float>(mat, position);
    case CV_32FC3:
      return LTMatAsString<cv::Vec3f>(mat, position);
    case CV_32FC4:
      return LTMatAsString<cv::Vec4f>(mat, position);
    case CV_64F:
      return LTMatAsString<double>(mat, position);
    case CV_64FC4:
      return LTMatAsString<cv::Vec4d>(mat, position);
    default:
      LTAssert(NO, @"Unsupported mat type to retrieve value from: %d", mat.type());
  }
}

template <typename T>
static NSString *LTMatAsString(const cv::Mat &mat, const std::vector<int> &position) {
  T value = mat.at<T>(position.data());
  cv::Mat cellMat(1, 1, mat.type(), cv::Scalar(value));
  std::stringstream message;
  message << cellMat;
  return [NSString stringWithCString:message.str().c_str() encoding:NSUTF8StringEncoding];
}

static NSString *LTHalfFloatMatAsString(const cv::Mat &mat, const std::vector<int> &position) {
  switch (mat.channels()) {
    case 1: {
      half value(mat.at<half>(position.data()));
      return [NSString stringWithFormat:@"[%g]", (float)value];
    } case 2: {
      cv::Vec2hf value(mat.at<cv::Vec2hf>(position.data()));
      return [NSString stringWithFormat:@"[%g, %g]", (float)value[0], (float)value[1]];
    } case 3: {
      cv::Vec3hf value(mat.at<cv::Vec3hf>(position.data()));
      return [NSString stringWithFormat:@"[%g, %g, %g]", (float)value[0], (float)value[1],
              (float)value[2]];
    } case 4: {
      cv::Vec4hf value(mat.at<cv::Vec4hf>(position.data()));
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
  LTVector3 rgb = src.rgb() + dst.rgb() * (1 - src.a());
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendDraken(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 rgb = std::min(src.rgb() * dst.a(), dst.rgb() * src.a()) + src.rgb() * (1 - dst.a()) +
      dst.rgb() * (1 - src.a());
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendMultiply(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 rgb = src.rgb() * dst.rgb() + src.rgb() * (1 - dst.a()) + dst.rgb() * (1 - src.a());
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendHardLight(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 below = 2 * src.rgb() * dst.rgb() + src.rgb() * (1 - dst.a()) +
      dst.rgb() * (1 - src.a());
  LTVector3 above = src.rgb() * (1 + dst.a()) + dst.rgb() * (1 + src.a()) -
      LTVector3(src.a() * dst.a()) - 2 * src.rgb() * dst.rgb();

  LTVector3 rgb = std::mix(below, above, std::step(0.5 * src.a(), src.rgb()));
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendSoftLight(const LTVector4 &src, const LTVector4 &dst) {
  float safeDa = (dst.a() > 0) ? dst.a() : dst.a() + 1;

  LTVector3 below = 2 * src.rgb() * dst.rgb() +
      dst.rgb() * (dst.rgb() / safeDa) * (LTVector3(src.a()) - 2 * src.rgb()) +
      src.rgb() * (1 - dst.a()) + dst.rgb() * (1 - src.a());
  LTVector3 above = 2 * dst.rgb() * (LTVector3(src.a()) - src.rgb()) +
      std::sqrt(dst.rgb() * dst.a()) * (2 * src.rgb() - LTVector3(src.a())) +
      src.rgb() * (1 - dst.a()) + dst.rgb() * (1 - src.a());

  LTVector3 rgb = std::mix(below, above, std::step(0.5 * src.a(), src.rgb()));
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendLighten(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 rgb = std::max(src.rgb() * dst.a(), dst.rgb() * src.a()) +
      src.rgb() * (1 - dst.a()) + dst.rgb() * (1 - src.a());
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendScreen(const LTVector4 &src, const LTVector4 &dst) {
  return src + dst - src * dst;
}

LTVector4 LTBlendOverlay(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 below = 2 * src.rgb() * dst.rgb() + src.rgb() * (1 - dst.a()) +
      dst.rgb() * (1 - src.a());
  LTVector3 above = src.rgb() * (1 + dst.a()) + dst.rgb() * (1 + src.a()) -
      2 * dst.rgb() * src.rgb() - LTVector3(dst.a() * src.a());

  LTVector3 rgb = std::mix(below, above, std::step(0.5 * dst.a(), dst.rgb()));
  float a = src.a() + dst.a() - src.a() * dst.a();
  return LTVector4(rgb, a);
}

LTVector4 LTBlendPlusLighter(const LTVector4 &src, const LTVector4 &dst) {
  return src + dst;
}

LTVector4 LTBlendPlusDarker(const LTVector4 &src, const LTVector4 &dst) {
  LTVector3 rgb = src.rgb() + dst.rgb() - LTVector3::ones();
  float a = src.a() + dst.a();
  return LTVector4(rgb, a);
}

cv::Vec4b LTBlend(const cv::Vec4b &oldColor, const cv::Vec4b &newColor, bool premultiplied,
                  LTBlendMode mode) {
  LTVector4 src = LTVector4(newColor);
  LTVector4 dst = LTVector4(oldColor);

  if (!premultiplied) {
    src = LTVector4(src.rgb() * src.a(), src.a());
    dst = LTVector4(dst.rgb() * dst.a(), dst.a());
  }

  LTVector4 blended;
  switch (mode) {
    case LTBlendModeNormal:
      blended = LTBlendNormal(src, dst);
      break;
    case LTBlendModeDarken:
      blended = LTBlendDraken(src, dst);
      break;
    case LTBlendModeMultiply:
      blended = LTBlendMultiply(src, dst);
      break;
    case LTBlendModeHardLight:
      blended = LTBlendHardLight(src, dst);
      break;
    case LTBlendModeSoftLight:
      blended = LTBlendSoftLight(src, dst);
      break;
    case LTBlendModeLighten:
      blended = LTBlendLighten(src, dst);
      break;
    case LTBlendModeScreen:
      blended = LTBlendScreen(src, dst);
      break;
    case LTBlendModeOverlay:
      blended = LTBlendOverlay(src, dst);
      break;
    case LTBlendModePlusLighter:
      blended = LTBlendPlusLighter(src, dst);
      break;
    case LTBlendModePlusDarker:
      blended = LTBlendPlusDarker(src, dst);
      break;
    default:
      LTMethodNotImplemented();
  }

  if (!premultiplied) {
    blended = blended.a() > 0 ?
        LTVector4(blended.rgb() / blended.a(), blended.a()) :
        LTVector4::zeros();
  }
  blended = std::round(blended * UCHAR_MAX) / UCHAR_MAX;
  blended = blended.clamp(0, 1);

  return LTLTVector4ToVec4b(blended);
}

cv::Rect LTCVRectWithCGRect(CGRect rect) {
  return cv::Rect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

cv::Vec4b LTLTVector4ToVec4b(LTVector4 value) {
  return (cv::Vec4b)value;
}

cv::Vec4f LTLTVector4ToVec4f(LTVector4 value) {
  return (cv::Vec4f)value;
}

cv::Vec4hf LTCVVec4hfFromScalar(float scalar) {
  return cv::Vec4hf(half(scalar), half(scalar), half(scalar), half(scalar));
}

cv::Vec4hf LTCVVec4hf(float r, float g, float b, float a) {
  return cv::Vec4hf(half(r), half(g), half(b), half(a));
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

cv::Mat4b LTGenerateCellsMat(CGSize matSize, CGSize cellSize) {
  LTParameterAssert(std::round(matSize) == matSize);
  LTParameterAssert(std::round(cellSize) == cellSize);

  CGSize gridSize = matSize / cellSize;
  LTParameterAssert(std::round(gridSize) == gridSize);

  cv::Mat4b mat(matSize.height, matSize.width);
  LTRandom *random = [[LTRandom alloc] initWithSeed:0];
  for (int i = 0; i < gridSize.height; ++i) {
    for (int j = 0; j < gridSize.width; ++j) {
      cv::Rect rect(j * cellSize.width, i * cellSize.height, cellSize.width, cellSize.height);
      cv::Vec4b color([random randomUnsignedIntegerBelow:256],
                      [random randomUnsignedIntegerBelow:256],
                      [random randomUnsignedIntegerBelow:256], 255);
      mat(rect).setTo(color);
    }
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
                              std::vector<int> *firstMismatch) {
  if (!expected.dims) {
    return YES;
  }

  cv::MatConstIterator_<T> expectedIterator = expected.begin<T>();
  auto actualIterator = actual.begin<T>();
  cv::MatConstIterator_<T> endIterator = expected.end<T>();

  while (expectedIterator != endIterator) {
    if (!LTCompareMatCell(*expectedIterator, *actualIterator, fuzziness,
                          std::is_fundamental<T>())) {
      if (firstMismatch) {
        firstMismatch->resize(expected.dims);

        // From unknown reason, the compiler doesn't recognize the pos function directly from
        // MatConstIterator_ type but only from its ancestor - MatConstIterator.
        static_cast<cv::MatConstIterator>(actualIterator).pos(firstMismatch->data());
      }
      return NO;
    }

    ++expectedIterator;
    ++actualIterator;
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

void LTWriteMatrices(const cv::Mat &expected, const cv::Mat &actual) {
  LTParameterAssert(actual.dims == 2 && expected.dims == 2, @"Non 2-dimenional matrices don't have "
                    @"writing support. acutal matrix is %d-dimensional and expected matrix is "
                    @"%d-dimensional", actual.dims, expected.dims);

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

static cv::Mat4b LTFourChannelMatrixFromTwoChannels(const cv::Mat2b &mat) {
  cv::Mat ones = cv::Mat::ones(mat.rows, mat.cols, CV_8U) * 255;
  cv::Mat zeros = cv::Mat::zeros(mat.rows, mat.cols, CV_8U);
  cv::Mat paddedMat(mat.rows, mat.cols, CV_8UC4);
  const int fromTo[] = {0, 2, 1, 1, 2, 0, 3, 3};
  Matrices inputs{mat, zeros, ones};
  Matrices outputs{paddedMat};
  cv::mixChannels(inputs, outputs, fromTo, 4);
  return paddedMat;
}

static void LTWriteMat(const cv::Mat &mat, NSString *path) {
  LTParameterAssert(mat.dims == 2, "Non 2-dimenional matrices don't have writing support. "
                    @"Input matrix is %d-dimensional.", mat.dims);

  switch (mat.type()) {
    case CV_8UC1:
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], mat);
      break;
    case CV_8UC2: {
      auto paddedMat = LTFourChannelMatrixFromTwoChannels(mat);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], paddedMat);
    } break;
    case CV_8UC3: {
      cv::Mat bgrMat;
      cv::cvtColor(mat, bgrMat, cv::COLOR_RGB2BGR);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_8UC4:
    case CV_16UC4: {
      cv::Mat bgrMat;
      cv::cvtColor(mat, bgrMat, cv::COLOR_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_16F: {
      cv::Mat1b converted;
      LTConvertMat(mat, &converted, converted.type());
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], converted);
    } break;
    case CV_16FC2:
    case CV_32FC2:
    case CV_32SC2: {
      cv::Mat2b converted;
      LTConvertMat(mat, &converted, converted.type());

      auto paddedMat = LTFourChannelMatrixFromTwoChannels(converted);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], paddedMat);
    } break;
    case CV_16U:
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], mat);
      break;
    case CV_32S: {
      cv::Mat converted(mat.rows, mat.cols, CV_8UC4, mat.data, mat.step[0]);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], converted);
    } break;
    case CV_32F:
    case CV_64F: {
      cv::Mat converted;
      mat.convertTo(converted, CV_8U, 255.0);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], converted);
    } break;
    case CV_32FC3: {
      cv::Mat converted;
      mat.convertTo(converted, CV_8UC3, 255.0);
      cv::Mat bgrMat;
      cv::cvtColor(converted, bgrMat, cv::COLOR_RGB2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    case CV_16FC4:
    case CV_32FC4:
    case CV_64FC4: {
      cv::Mat converted;
      mat.convertTo(converted, CV_8UC4, 255.0);
      cv::Mat bgrMat;
      cv::cvtColor(converted, bgrMat, cv::COLOR_RGBA2BGRA);
      cv::imwrite([path cStringUsingEncoding:NSUTF8StringEncoding], bgrMat);
    } break;
    default:
      LTAssert(NO, @"Unsupported mat type given: %d", mat.type());
  }
}
