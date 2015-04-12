// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVExtensions.h"

#import "LTGLKitExtensions.h"
#import "LTImage.h"

using half_float::half;

void LTConvertToSameNumberOfChannels(const cv::Mat &input, cv::Mat *output, int type);
void LTConvertToSameDepth(const cv::Mat &input, cv::Mat *output, int type);
NSString *LTPathForResourceNearClass(Class classInBundle, NSString *name);
NSString *LTPathForResourceInBundle(NSBundle *bundle, NSString *name);

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
  if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_16F) {
    LTConvertHalfFloat<float, half>(input, output);
  } else if (input.depth() == CV_16F && CV_MAT_DEPTH(type) == CV_32F) {
    LTConvertHalfFloat<half, float>(input, output);
  } else if (input.depth() == CV_16F && CV_MAT_DEPTH(type) == CV_8U) {
    LTConvertHalfFloat<half, uchar>(input, output, 255);
  } else if (input.depth() == CV_16F || CV_MAT_DEPTH(type) == CV_16F) {
    LTAssert(NO, @"Unsupported half-float conversion: %d to %d", input.depth(), CV_MAT_DEPTH(type));
  } else {
    double alpha = 1;
    if (input.depth() == CV_32F && CV_MAT_DEPTH(type) == CV_8U) {
      alpha = 255;
    } else if (input.depth() == CV_8U && CV_MAT_DEPTH(type) == CV_32F) {
      alpha = 1.0 / 255.0;
    }
    input.convertTo(*output, type, alpha);
  }
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

void LTPreDivideMat(cv::Mat *mat) {
  LTParameterAssert(mat->type() == CV_8UC4, @"preDivide only works on byte RGBA images");
  std::transform(mat->begin<cv::Vec4b>(), mat->end<cv::Vec4b>(), mat->begin<cv::Vec4b>(),
                 [](const cv::Vec4b &color) -> cv::Vec4b {
    if (!color[3]) {
      return cv::Vec4b();
    }
    LTVector3 rgb = LTVector3(color[0], color[1], color[2]) / ((color[3] / 255.0) ?: 1.0);
    rgb = std::min(std::round(rgb), LTVector3(UCHAR_MAX, UCHAR_MAX, UCHAR_MAX));
    return cv::Vec4b(rgb.r(), rgb.g(), rgb.b(), color[3]);
  });
}

UIImage *LTLoadImage(Class classInBundle, NSString *name) {
  NSString *path = LTPathForResourceNearClass(classInBundle, name);
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  LTParameterAssert(image, @"Given image name '%@' cannot be loaded", name);

  return image;
}

cv::Mat LTMatFromImage(UIImage *image, BOOL preDivide) {
  cv::Mat mat = [[LTImage alloc] initWithImage:image].mat;
  if (preDivide) {
    LTPreDivideMat(&mat);
  }
  return mat;
}

cv::Mat LTLoadMat(Class classInBundle, NSString *name, BOOL preDivide) {
  return LTMatFromImage(LTLoadImage(classInBundle, name), preDivide);
}

cv::Mat LTLoadMatFromMainBundle(NSString *name, BOOL preDivide) {
  return LTMatFromImage([UIImage imageNamed:name], preDivide);
}

cv::Mat LTLoadMatFromBundle(NSBundle *bundle, NSString *name, BOOL preDivide) {
  NSString *path = LTPathForResourceInBundle(bundle, name);
  return LTMatFromImage([UIImage imageWithContentsOfFile:path], preDivide);
}

NSString *LTPathForResourceNearClass(Class classInBundle, NSString *name) {
  NSBundle *bundle = [NSBundle bundleForClass:classInBundle];
  return LTPathForResourceInBundle(bundle, name);
}

NSString *LTPathForResourceInBundle(NSBundle *bundle, NSString *name) {
  NSString *resource = [name stringByDeletingPathExtension];
  NSString *type = [name pathExtension];

  NSString *path = [bundle pathForResource:resource ofType:type];
  LTParameterAssert(path, @"Given image name '%@' doesn't exist in bundle '%@'", name, bundle);

  return path;
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
  // TODO: (yaron) implement a half-float <--> float converter when needed.
  switch (image.type()) {
    case CV_8U: {
      uchar value = image.at<uchar>(location.y, location.x);
      return LTVector4(value / 255.f, 0, 0, 0);
    }
    case CV_8UC4: {
      cv::Vec4b value = image.at<cv::Vec4b>(location.y, location.x);
      return LTVector4(value(0) / 255.f, value(1) / 255.f, value(2) / 255.f, value(3) / 255.f);
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
      [LTGLException raise:kLTTextureUnsupportedFormatException
                    format:@"Unsupported matrix type: %d", image.type()];
      __builtin_unreachable();
  }
}

