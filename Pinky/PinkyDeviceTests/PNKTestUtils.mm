// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "PNKTestUtils.h"

#import <LTKit/LTMMInputFile.h>
#import <LTKit/NSBundle+Path.h>

#import "MPSImage+Factory.h"

NS_ASSUME_NONNULL_BEGIN

MPSImage *PNKImageMake(id<MTLDevice> device, MPSImageFeatureChannelFormat format,
                       NSUInteger width, NSUInteger height, NSUInteger channels) {
  return [MPSImage pnk_imageWithDevice:device format:format width:width height:height
                              channels:channels];
}

MPSImage *PNKImageMakeUnorm(id<MTLDevice> device, NSUInteger width, NSUInteger height,
                            NSUInteger channels) {
  return [MPSImage pnk_unorm8ImageWithDevice:device width:width height:height channels:channels];
}

cv::Mat1f PNKLoadFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(float) == 0, @"File size must be a multiply of "
                    "%lu, got %lu", sizeof(float), tensorFile.size);

  cv::Mat1f tensorData(1, (int)tensorFile.size / sizeof(float));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

cv::Mat1hf PNKLoadHalfFloatTensorFromBundleResource(NSBundle *bundle, NSString *resource) {
  NSString * _Nullable path = [bundle lt_pathForResource:resource];
  LTParameterAssert(path, @"File %@ from bundle %@ failed to load", resource, bundle);
  NSError *error;
  LTMMInputFile *tensorFile = [[LTMMInputFile alloc] initWithPath:path error:&error];
  LTParameterAssert(tensorFile, @"Failed reading file");
  LTParameterAssert((int)tensorFile.size % sizeof(half_float::half) == 0, @"File size must be a "
                    "multiply of %lu, got %lu", sizeof(float) / 2, tensorFile.size);

  cv::Mat1hf tensorData(1, (int)tensorFile.size / sizeof(half_float::half));
  memcpy(tensorData.data, tensorFile.data, tensorFile.size);
  return tensorData;
}

cv::Mat PNKFillMatrix(int rows, int columns, int channels) {
  cv::Mat1hf matrix(rows * columns, channels);
  for (int i = 0; i < rows; ++i) {
    for (int j = 0; j < columns; ++j) {
      for (int k = 0; k < channels; ++k) {
        matrix.at<half_float::half>(i * columns + j, k) =
            (half_float::half)((i + j + k) % 2);
      }
    }
  }
  return matrix.reshape(channels, rows);
}

template <typename T, int cvType>
cv::Mat PNKGenerateChannelwiseConstantMatrix(NSUInteger rows, NSUInteger columns,
                                             const std::vector<T> &values) {
  int channels = (int)values.size();

  cv::Mat matrix = cv::Mat((int)(rows * columns), channels, cvType);

  for (int i = 0; i < matrix.rows; i++) {
    for (int j = 0; j < channels; j++) {
      matrix.at<T>(i, j) = values[j];
    }
  }

  return matrix.reshape(channels, (int)rows);
}

cv::Mat PNKGenerateChannelwiseConstantUcharMatrix(NSUInteger rows, NSUInteger columns,
                                                  const std::vector<uchar> &values) {
  return PNKGenerateChannelwiseConstantMatrix<uchar, CV_8U>(rows, columns, values);
}

cv::Mat PNKGenerateChannelwiseConstantHalfFloatMatrix(NSUInteger rows, NSUInteger columns,
                                                      const std::vector<half_float::half> &values) {
  return PNKGenerateChannelwiseConstantMatrix<half_float::half, CV_16F>(rows, columns, values);
}

half_float::half PNKActivatedValue(half_float::half value, int channel,
                                   pnk::ActivationType activationType, const cv::Mat1f &alpha,
                                   const cv::Mat1f &beta) {
  half_float::half alphaParameter;
  half_float::half betaParameter;

  switch (activationType) {
    case pnk::ActivationTypeIdentity:
      return value;
    case pnk::ActivationTypeAbsolute:
      return value < (half_float::half)0.0 ? -value : value;
    case pnk::ActivationTypeReLU:
      return std::max(value, (half_float::half)0.0);
    case pnk::ActivationTypeLeakyReLU:
      alphaParameter = (half_float::half)alpha(0);
      return value < (half_float::half)0.0 ? (alphaParameter * value) : value;
    case pnk::ActivationTypePReLU:
      alphaParameter = (half_float::half)alpha((int)channel);
      return value < (half_float::half)0.0 ? (alphaParameter * value) : value;
    case pnk::ActivationTypeTanh:
      return (half_float::half)std::tanh(value);
    case pnk::ActivationTypeScaledTanh:
      alphaParameter = (half_float::half)alpha(0);
      betaParameter = (half_float::half)beta(0);
      return alphaParameter * (half_float::half)std::tanh(betaParameter * value);
    case pnk::ActivationTypeSigmoid:
      return (half_float::half)1.0 / ((half_float::half)1.0 + (half_float::half)std::exp(-value));
    case pnk::ActivationTypeSigmoidHard:
      alphaParameter = (half_float::half)alpha(0);
      betaParameter = (half_float::half)beta(0);
      return (half_float::half)std::clamp(alphaParameter * value + betaParameter,
                                          (half_float::half)0.0, (half_float::half)1.0);
    case pnk::ActivationTypeLinear:
      alphaParameter = (half_float::half)alpha(0);
      betaParameter = (half_float::half)beta(0);
      return alphaParameter * value + betaParameter;
    case pnk::ActivationTypeELU:
      alphaParameter = (half_float::half)alpha(0);
      return value < (half_float::half)0.0 ?
         (alphaParameter * (half_float::half)(std::exp(value) - 1)) : value;
    case pnk::ActivationTypeThresholdedReLU:
      alphaParameter = (half_float::half)alpha(0);
      return value < (half_float::half)alphaParameter ? (half_float::half)0.0 : value;
    case pnk::ActivationTypeSoftsign:
      return value / (half_float::half)(1 + std::abs(value));
    case pnk::ActivationTypeSoftplus:
      return (half_float::half)std::log(1 + std::exp(value));
    case pnk::ActivationTypeParametricSoftplus:
      alphaParameter = (half_float::half)alpha((int)channel);
      betaParameter = (half_float::half)beta((int)channel);
      return alphaParameter * (half_float::half)std::log(1 + std::exp(betaParameter * value));
  }
}

NS_ASSUME_NONNULL_END
