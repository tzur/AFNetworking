// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

#import <Accelerate/Accelerate.h>
#import <LTKit/NSBundle+Path.h>

#import "LTGLKitExtensions.h"
#import "LTImage.h"

using half_float::half;

void LTConvertToSameNumberOfChannels(const cv::Mat &input, cv::Mat *output, int type);
void LTConvertToSameDepth(const cv::Mat &input, cv::Mat *output, int type);

void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type) {
  LTAssert(&input != output, @"Conversion cannot be made in-place");

  // Type is equal -- copy directly to output.
  if (input.type() == type) {
    input.copyTo(*output);
    return;
  }

  BOOL differentDepth = input.depth() != CV_MAT_DEPTH(type);
  BOOL differentChannels = input.channels() != CV_MAT_CN(type);

  cv::Mat sameChannels;

  // Convert channels if needed.
  if (!differentChannels) {
    sameChannels = input;
  } else {
    if (differentDepth) {
      LTConvertToSameNumberOfChannels(input, &sameChannels, type);
    } else {
      LTConvertToSameNumberOfChannels(input, output, type);
      sameChannels = *output;
    }
  }

  // Convert to the correct data type, if needed.
  if (differentDepth) {
    LTConvertToSameDepth(sameChannels, output, type);
  }
}

void LTConvertToSameNumberOfChannels(const cv::Mat &input, cv::Mat *output, int type) {
  // Output will be with the same depth of input, but with correct number of target channels.
  output->create(input.size(), CV_MAKETYPE(input.depth(), CV_MAT_CN(type)));

  Matrices inputs{input};
  Matrices outputs{*output};

  // Add zero matrix if output needs channel padding.
  if (CV_MAT_CN(type) - input.channels() > 0) {
    inputs.push_back(cv::Mat::zeros(input.size(), input.depth()));
  }

  // Formulate fromTo array. Start by copying channels from the input, and move to copy the zero
  // channel if padding is needed.
  std::vector<int> fromTo;
  for (int channel = 0; channel < CV_MAT_CN(type); ++channel) {
    if (channel < input.channels()) {
      fromTo.push_back(channel);
    } else {
      fromTo.push_back(input.channels());
    }
    fromTo.push_back(channel);
  }

  cv::mixChannels(inputs, outputs, &fromTo[0], fromTo.size() / 2);
}

void LTConvertToSameDepth(const cv::Mat &input, cv::Mat *output, int type) {
  output->create(input.size(), type);
  if (CV_MAT_DEPTH(type) == CV_16F) {
    LTConvertToHalfFloat(input, output);
  } else if (input.depth() == CV_16F) {
    LTConvertFromHalfFloat(input, output);
  } else {
    double alpha = 1;
    switch (input.depth()) {
      case CV_8U:
        if (CV_MAT_DEPTH(type) == CV_32F || CV_MAT_DEPTH(type) == CV_64F) {
          alpha = 1.0 / std::numeric_limits<uchar>::max();
        }
        break;
      case CV_16U:
        if (CV_MAT_DEPTH(type) == CV_32F || CV_MAT_DEPTH(type) == CV_64F) {
          alpha = 1.0 / std::numeric_limits<ushort>::max();
        }
        break;
      case CV_32F:
      case CV_64F:
        if (CV_MAT_DEPTH(type) == CV_8U) {
          alpha = std::numeric_limits<uchar>::max();
        } else if (CV_MAT_DEPTH(type) == CV_16U){
          alpha = std::numeric_limits<ushort>::max();
        }
        break;
    }
    input.convertTo(*output, type, alpha);
  }
}

static inline vImage_Buffer LTConvertMatToVImageBuffer(const cv::Mat &mat,
                                                       BOOL usePixelCountAsWidth = NO) {
  return {
    .data = mat.data,
    .height = (vImagePixelCount)mat.rows,
    .width = (vImagePixelCount)mat.cols * (usePixelCountAsWidth ? mat.channels() : 1),
    .rowBytes = mat.step[0]
  };
}

void LTConvertToHalfFloat(const cv::Mat &input, cv::Mat *output) {
  LTParameterAssert(input.size() == output->size(),
                    @"Input size (%d, %d) must equal output size (%d, %d)",
                    input.cols, input.rows, output->cols, output->rows);
  LTParameterAssert(input.channels() == output->channels(),
                    @"Input must have the same number of channels (%d) as output (%d)",
                    input.channels(), output->channels());
  LTParameterAssert(input.depth() == CV_8U || input.depth() == CV_32F,
                    @"Input depth (%d) must be CV_8U or CV_32F", input.depth());
  LTParameterAssert(output->depth() == CV_16F, @"Output depth (%d) must be CV_16F", input.depth());

  vImage_Buffer source = LTConvertMatToVImageBuffer(input, YES);
  vImage_Buffer destination = LTConvertMatToVImageBuffer(*output, YES);

  vImage_Error errorCode;

  switch (input.depth()) {
    case CV_8U:
      errorCode = vImageConvert_Planar8toPlanar16F(&source, &destination, NULL);
      break;
    case CV_32F:
      errorCode = vImageConvert_PlanarFtoPlanar16F(&source, &destination, NULL);
      break;
    default:
      LTAssert(NO, @"Invalid input depth %d", input.depth());
  }

  LTAssert(!errorCode, @"Failed to convert to half-float, with error code %zd", errorCode);
}

void LTConvertFromHalfFloat(const cv::Mat &input, cv::Mat *output) {
  LTParameterAssert(input.size() == output->size(),
                    @"Input size (%d, %d) must equal output size (%d, %d)",
                    input.cols, input.rows, output->cols, output->rows);
  LTParameterAssert(input.channels() == output->channels(),
                    @"Input must have the same number of channels (%d) as output (%d)",
                    input.channels(), output->channels());
  LTParameterAssert(input.depth() == CV_16F, @"Input depth (%d) must be CV_16F", input.depth());
  LTParameterAssert(output->depth() == CV_8U || output->depth() == CV_32F,
                    @"Output depth (%d) must be CV_8U or CV_32F", input.type());

  vImage_Buffer source = LTConvertMatToVImageBuffer(input, YES);
  vImage_Buffer destination = LTConvertMatToVImageBuffer(*output, YES);

  vImage_Error errorCode;

  switch (output->depth()) {
    case CV_8U:
      errorCode = vImageConvert_Planar16FtoPlanar8(&source, &destination, NULL);
      break;
    case CV_32F:
      errorCode = vImageConvert_Planar16FtoPlanarF(&source, &destination, NULL);
      break;
    default:
      LTAssert(NO, @"Invalid input depth %d", input.depth());
  }

  LTAssert(!errorCode, @"Failed to convert from half-float, with error code %zd", errorCode);
}

void LTInPlaceFFTShift(cv::Mat *mat) {
  int rows = mat->rows / 2;
  int cols = mat->cols / 2;

  cv::Mat q0 = (*mat)(cv::Rect(0, 0, rows, cols));
  cv::Mat q1 = (*mat)(cv::Rect(rows, 0, rows, cols));
  cv::Mat q2 = (*mat)(cv::Rect(0, cols, rows, cols));
  cv::Mat q3 = (*mat)(cv::Rect(rows, cols, rows, cols));

  // Shuffle matrix quarters.
  cv::Mat1f temp(rows, cols);
  q0.copyTo(temp);
  q3.copyTo(q0);
  temp.copyTo(q3);
  q1.copyTo(temp);
  q2.copyTo(q1);
  temp.copyTo(q2);
}

void LTUnpremultiplyMat(const cv::Mat &input, cv::Mat *output) {
  LTParameterAssert(input.size() == output->size(),
                    @"Input size (%d, %d) must equal output size (%d, %d)", input.rows, input.cols,
                    output->rows, output->cols);
  LTParameterAssert(input.type() == output->type(),
                    @"Input type (%d) must equal output type (%d)", input.type(), output->type());
  LTParameterAssert(input.type() == CV_32FC4 || input.type() == CV_8UC4,
                    @"Input must be of type CV_32FC4 or CV_8UC4, got: %d", input.type());

  vImage_Buffer source = LTConvertMatToVImageBuffer(input);
  vImage_Buffer destination = LTConvertMatToVImageBuffer(*output);

  vImage_Error errorCode;

  switch (input.depth()) {
    case CV_8U:
      errorCode = vImageUnpremultiplyData_RGBA8888(&source, &destination, NULL);
      break;
    case CV_32F:
      errorCode = vImageUnpremultiplyData_RGBAFFFF(&source, &destination, NULL);
      break;
    default:
      LTAssert(NO, @"Invalid input depth %d", input.depth());
  }

  LTParameterAssert(errorCode == kvImageNoError, @"vImageUnpremultiplyData failed with error %zd",
                    errorCode);
}

void LTPremultiplyMat(const cv::Mat &input, cv::Mat *output) {
  LTParameterAssert(input.size() == output->size(),
                    @"Input size (%d, %d) must equal output size (%d, %d)", input.rows, input.cols,
                    output->rows, output->cols);
  LTParameterAssert(input.type() == output->type(),
                    @"Input type (%d) must equal output type (%d)", input.type(), output->type());
  LTParameterAssert(input.type() == CV_32FC4 || input.type() == CV_8UC4,
                    @"Input must be of type CV_32FC4 or CV_8UC4, got: %d", input.type());

  vImage_Buffer source = LTConvertMatToVImageBuffer(input);
  vImage_Buffer destination = LTConvertMatToVImageBuffer(*output);

  vImage_Error errorCode;

  switch (input.depth()) {
    case CV_8U:
      errorCode = vImagePremultiplyData_RGBA8888(&source, &destination, NULL);
      break;
    case CV_32F:
      errorCode = vImagePremultiplyData_RGBAFFFF(&source, &destination, NULL);
      break;
    default:
      LTAssert(NO, @"Invalid input depth %d", input.depth());
  }

  LTParameterAssert(errorCode == kvImageNoError, @"ImagePremultiplyData failed with error %zd",
                    errorCode);
}

UIImage *LTLoadImage(Class classInBundle, NSString *name) {
  NSString *path = [NSBundle lt_pathForResource:name nearClass:classInBundle];
  LTParameterAssert(path, @"Image with name %@ in bundle of class %@ does not exist", name,
                    classInBundle);
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  LTParameterAssert(image, @"Given image name '%@' cannot be loaded", name);

  return image;
}

cv::Mat LTMatFromImage(UIImage *image, BOOL unpremultiply) {
  cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
  if (unpremultiply) {
    LTUnpremultiplyMat(mat, &mat);
  }
  return mat;
}

cv::Mat LTLoadMat(Class classInBundle, NSString *name, BOOL unpremultiply) {
  return LTMatFromImage(LTLoadImage(classInBundle, name), unpremultiply);
}

cv::Mat LTLoadMatFromMainBundle(NSString *name, BOOL unpremultiply) {
  return LTMatFromImage([UIImage imageNamed:name], unpremultiply);
}

cv::Mat LTLoadMatFromBundle(NSBundle *bundle, NSString *name, BOOL unpremultiply) {
  NSString *path = [bundle lt_pathForResource:name];
  LTParameterAssert(path, @"Given image name '%@' cannot be found in the bundle %@", name, bundle);
  return LTMatFromImage([UIImage imageWithContentsOfFile:path], unpremultiply);
}

static double LTNormalizationFactorForGaussianMat(const cv::Mat &mat, double sigma) {
  CGSize radius = CGSizeMake(mat.cols / 2 - 1, mat.rows / 2 - 1);
  double x = (mat.cols % 2) ? 0 : 0.5 / radius.width;
  double y = (mat.rows % 2) ? 0 : 0.5 / radius.height;
  return std::exp(-(x * x + y * y) * (1.0 / (2.0 * sigma * sigma)));
}

cv::Mat1hf LTCreateGaussianMat(CGSize size, double sigma, BOOL normalized) {
  using half_float::half;
  cv::Mat1hf mat(size.height, size.width);
  if (mat.rows <= 2 && mat.cols <= 2) {
    std::fill(mat.begin(), mat.end(), half(1));
    return mat;
  }

  std::fill(mat.begin(), mat.end(), half(0));
  CGSize radius = CGSizeMake(mat.cols / 2 - 1, mat.rows / 2 - 1);
  double inv2SigmaSquare = 1.0 / (2.0 * sigma * sigma);
  double maxValue = normalized ? LTNormalizationFactorForGaussianMat(mat, sigma) : 1;
  for (int i = 0; i < 2 * radius.height; ++i) {
    for (int j = 0; j < 2 * radius.width; ++j) {
      double y = (i - radius.height + 0.5) / radius.height;
      double x = (j - radius.width + 0.5) / radius.width;
      double squaredDistance = x * x + y * y;
      double arg = -squaredDistance * inv2SigmaSquare;
      mat(i + 1, j + 1) = half(std::exp(arg) / maxValue);
    }
  }
  return mat;
}

cv::Mat1f LTMatFromGLKMatrix3(GLKMatrix3 matrix) {
  return cv::Mat1f(3, 3) << matrix.m00, matrix.m01, matrix.m02, matrix.m10, matrix.m11, matrix.m12,
      matrix.m20, matrix.m21, matrix.m22;
}

LTVector4 LTPixelValueFromImage(const cv::Mat &image, cv::Point2i location) {
  switch (image.type()) {
    case CV_8U: {
      uchar value = image.at<uchar>(location.y, location.x);
      return LTVector4(value / 255.f, 0, 0, 0);
    }
    case CV_8UC4: {
      cv::Vec4b value = image.at<cv::Vec4b>(location.y, location.x);
      return LTVector4(value(0) / 255.f, value(1) / 255.f, value(2) / 255.f, value(3) / 255.f);
    }
    case CV_16F: {
      half value = image.at<half>(location.y, location.x);
      return LTVector4(float(value), 0, 0, 0);
    }
    case CV_16FC4: {
      cv::Vec4hf value = image.at<cv::Vec4hf>(location.y, location.x);
      return LTVector4(float(value(0)), float(value(1)), float(value(2)), float(value(3)));
    }
    case CV_32F: {
      float value = image.at<float>(location.y, location.x);
      return LTVector4(value, 0, 0, 0);
    }
    case CV_32FC4: {
      cv::Vec4f value = image.at<cv::Vec4f>(location.y, location.x);
      return LTVector4(value(0), value(1), value(2), value(3));
    }
    default:
      LTParameterAssert(NO, @"Unsupported matrix type: %d", image.type());
  }
}

cv::Mat4b LTWhiteGrayCheckerboardPattern(CGSize size, uint tileSize) {
  return LTCheckerboardPattern(size, tileSize, cv::Vec4b (193, 193, 193, 255),
                               cv::Vec4b (255, 255, 255, 255));
}

cv::Mat4b LTCheckerboardPattern(CGSize size, uint tileSize, cv::Vec4b firstColor,
                                cv::Vec4b secondColor) {
  LTParameterAssert(size.width > 0, @"Invalid width (%g) provided", size.width);
  LTParameterAssert(size.height > 0, @"Invalid height (%g) provided", size.height);
  LTParameterAssert(tileSize, @"Invalid tile size (%u) provided", tileSize);
  cv::Mat4b checkerboard(size.height, size.width, secondColor);

  int stepSize = 2 * tileSize;
  for(int i = 0; i < size.width; i += tileSize){
    for(int j = (i % stepSize); j < size.height; j += stepSize){
      int width = MIN(tileSize, size.width - i);
      int height = MIN(tileSize, size.height - j);
      checkerboard(cv::Rect(i, j, width, height)) = firstColor;
    }
  }

  return checkerboard;
}

cv::Mat LTRowSubset(const cv::Mat &mat, const std::vector<int> &indices) {
  cv::Mat result(cv::Size(mat.cols, (int)indices.size()), mat.type());

  uchar *output = result.data;

  for (int index : indices) {
    LTParameterAssert(index >= 0 && index < mat.rows, @"Indices must be in the range [0, %d], "
                      "got: %d", mat.rows - 1, index);

    const uchar *start = mat.ptr(index);
    const uchar *end = start + mat.elemSize() * mat.cols;

    memcpy(output, start, end - start);
    output += (end - start);
  }

  return result;
}

cv::Mat LTRotateHalfPiClockwise(const cv::Mat &input, NSInteger rotations, BOOL mirrorHorizontal,
                                cv::Mat * _Nullable intermediateMat) {
  cv::Mat output;
  LTRotateHalfPiClockwise(input, &output, rotations, mirrorHorizontal, intermediateMat);
  return output;
}

void LTRotateHalfPiClockwise(const cv::Mat &input, cv::Mat *output,
                             NSInteger rotations, BOOL mirrorHorizontal,
                             cv::Mat * _Nullable intermediate) {
  rotations = ((rotations % 4) + 4) % 4;
  if (!intermediate) {
    intermediate = output;
  }

  switch (rotations) {
    case 0:
      if (mirrorHorizontal) {
        cv::flip(input, *output, 1);
      } else {
        input.copyTo(*output);
      }
      break;
    case 1:
      if (mirrorHorizontal) {
        cv::transpose(input, *output);
      } else {
        cv::transpose(input, *intermediate);
        cv::flip(*intermediate, *output, 1);
      }
      break;
    case 2:
      cv::flip(input, *output, mirrorHorizontal ? 0 : -1);
      break;
    case 3:
      cv::transpose(input, *intermediate);
      cv::flip(*intermediate, *output, mirrorHorizontal ? -1 : 0);
      break;
  }
}
