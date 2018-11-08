// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKConvolutionTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

cv::Mat1f PNKFillKernel(int kernelWidth, int kernelHeight, int inputChannels, int outputChannels,
                        int groups) {
  int inputChannelsPerGroup = inputChannels / groups;
  int outputChannelsPerGroup = outputChannels / groups;
  int dims[] = {groups, outputChannelsPerGroup, kernelHeight, kernelWidth, inputChannelsPerGroup};
  cv::Mat1f kernel(5, dims);

  for (int i = 0; i < groups; ++i) {
    for (int j = 0; j < outputChannelsPerGroup; ++j) {
      for (int k = 0; k < kernelHeight; ++k) {
        for (int m = 0; m < kernelWidth; ++m) {
          for (int n = 0; n < inputChannelsPerGroup; ++n) {
            int index[] = {i, j, k, m, n};
            kernel.at<float>(index) = (i + j + k + m + n) % 5 - 2;
          }
        }
      }
    }
  }

  return kernel;
}

cv::Mat PNKCalculateConvolution(pnk::PaddingType padding, const cv::Mat &inputMatrix,
                                const cv::Mat &kernel, int dilationX, int dilationY, int strideX,
                                int strideY, pnk::ActivationType activationType,
                                const cv::Mat &alpha, const cv::Mat &beta) {
  LTAssert(kernel.dims == 5);
  cv::MatSize kernelSize = kernel.size;

  int groups = kernelSize[0];
  int outputChannelsPerGroup = kernelSize[1];
  int kernelHeight = kernelSize[2];
  int kernelWidth = kernelSize[3];
  int inputChannelsPerGroup = kernelSize[4];

  int inputChannels = inputChannelsPerGroup * groups;
  int outputChannels = outputChannelsPerGroup * groups;
  LTAssert(inputChannels == inputMatrix.channels());

  int inputRows = inputMatrix.rows;
  int inputColumns = inputMatrix.cols;
  int outputRows, outputColumns;
  if (padding == pnk::PaddingTypeSame) {
    outputRows = (inputRows - 1) / strideY + 1;
    outputColumns = (inputColumns - 1) / strideX + 1;
  } else {
    outputRows = (inputRows - (kernelHeight - 1) * dilationY - 1) / strideY + 1;
    outputColumns = (inputColumns - (kernelWidth - 1) * dilationX - 1) / strideX + 1;
  }

  cv::Mat input = inputMatrix.reshape(1, inputRows * inputColumns);
  cv::Mat1hf output = cv::Mat1hf::zeros(outputRows * outputColumns, outputChannels);

  int paddingLeft, paddingTop;
  if (padding == pnk::PaddingTypeSame) {
    int strideResidualX = (inputColumns - 1) % strideX + 1;
    paddingLeft = std::max((kernelWidth - 1) * dilationX + 1 - strideResidualX, 0) / 2;
    int strideResidualY = (inputRows - 1) % strideY + 1;
    paddingTop = std::max((kernelHeight - 1) * dilationY + 1 - strideResidualY, 0) / 2;
  } else {
    paddingLeft = 0;
    paddingTop = 0;
  }

  for (int group = 0; group < groups; ++group) {
    for (int outputChannel = 0; outputChannel < outputChannelsPerGroup; ++outputChannel) {
      for (int outputRow = 0; outputRow < outputRows; ++outputRow) {
        for (int outputColumn = 0; outputColumn < outputColumns; ++outputColumn) {
          half_float::half result = (half_float::half)0.0;
          for (int inputChannel = 0; inputChannel < inputChannelsPerGroup; ++inputChannel) {
            for (int kernelY = 0; kernelY < kernelHeight; ++kernelY) {
              for (int kernelX = 0; kernelX < kernelWidth; ++kernelX) {
                int indexInKernel[] = {group, outputChannel, kernelY, kernelX, inputChannel};
                float weight = (float)kernel.at<float>(indexInKernel);
                int inputRow = outputRow * strideY - paddingTop + kernelY * dilationY;
                int inputColumn = outputColumn * strideX - paddingLeft + kernelX * dilationX;
                if (inputRow < 0 || inputRow >= inputRows || inputColumn < 0 ||
                    inputColumn >= inputColumns) {
                  continue;
                }
                result += weight * input.at<half_float::half>(inputRow * inputColumns + inputColumn,
                                                              group * inputChannelsPerGroup +
                                                              inputChannel);
              }
            }
          }
          output.at<half_float::half>(outputRow * outputColumns + outputColumn,
                                      group * outputChannelsPerGroup + outputChannel) = result;
        }
      }
    }
  }

  cv::Mat outputMat = output.reshape(outputChannels, outputRows);
  cv::Mat activatedOutputMat = PNKCalculateActivation(outputMat, activationType, alpha, beta);
  return activatedOutputMat;
}

cv::Mat PNKCalculateActivation(const cv::Mat &inputMatrix, pnk::ActivationType activationType,
                               const cv::Mat &alpha, const cv::Mat &beta) {
  int rows = inputMatrix.rows;
  int columns = inputMatrix.cols;
  int channels = inputMatrix.channels();
  cv::Mat input = inputMatrix.reshape(1, rows * columns);
  cv::Mat1hf output = cv::Mat1hf::zeros(rows * columns, channels);

  for (int row = 0; row < rows; ++row) {
    for (int column = 0; column < columns; ++column) {
      for (int channel = 0; channel < channels; ++channel) {
        half_float::half value = input.at<half_float::half>(row * columns + column, channel);
        half_float::half activatedValue = PNKActivatedValue(value, channel, activationType, alpha,
                                                            beta);
        output.at<half_float::half>(row * columns + column, channel) = activatedValue;
      }
    }
  }

  cv::Mat outputMat = output.reshape(channels, rows);
  return outputMat;
}

pnk::ConvolutionKernelModel PNKBuildConvolutionModel(NSUInteger kernelWidth,
                                                     NSUInteger kernelHeight,
                                                     NSUInteger inputChannels,
                                                     NSUInteger outputChannels,
                                                     NSUInteger groups,
                                                     NSUInteger dilationX,
                                                     NSUInteger dilationY,
                                                     NSUInteger strideX,
                                                     NSUInteger strideY,
                                                     pnk::PaddingType paddingType) {
  cv::Mat kernelWeights = PNKFillKernel((int)kernelWidth, (int)kernelHeight, (int)inputChannels,
                                        (int)outputChannels, (int)groups);

  return {
    .kernelWidth = kernelWidth,
    .kernelHeight = kernelHeight,
    .kernelChannels = inputChannels,
    .groups = groups,
    .inputFeatureChannels = inputChannels,
    .outputFeatureChannels = outputChannels,
    .strideX = strideX,
    .strideY = strideY,
    .dilationX = dilationX,
    .dilationY = dilationY,
    .padding = paddingType,
    .isDeconvolution = NO,
    .hasBias = NO,
    .deconvolutionOutputSize = CGSizeNull,
    .kernelWeights = kernelWeights
  };
};

pnk::ActivationKernelModel PNKBuildActivationModel(NSUInteger featureChannels,
                                                   pnk::ActivationType activationType) {
  cv::Mat1f alpha, beta;

  switch (activationType) {
    case pnk::ActivationTypeIdentity:
    case pnk::ActivationTypeAbsolute:
    case pnk::ActivationTypeReLU:
    case pnk::ActivationTypeTanh:
    case pnk::ActivationTypeSigmoid:
    case pnk::ActivationTypeSoftsign:
    case pnk::ActivationTypeSoftplus:
      alpha = cv::Mat1f();
      beta = cv::Mat1f();
      break;
    case pnk::ActivationTypeLeakyReLU:
    case pnk::ActivationTypeELU:
      alpha = cv::Mat1f(1, 1);
      beta = cv::Mat1f();
      break;
    case pnk::ActivationTypePReLU:
      alpha = cv::Mat1f(1, (int)featureChannels);
      beta = cv::Mat1f();
      break;
    case pnk::ActivationTypeScaledTanh:
    case pnk::ActivationTypeSigmoidHard:
    case pnk::ActivationTypeLinear:
    case pnk::ActivationTypeParametricSoftplus:
      alpha = cv::Mat1f(1, 1);
      beta = cv::Mat1f(1, 1);
      break;
  }

  cv::randu(alpha, 0.5, 2);
  cv::randu(beta, -1, 1);

  return {
    .activationType = activationType,
    .alpha = alpha,
    .beta = beta
  };
};

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
      return std::clamp<half_float::half>(alphaParameter * value + betaParameter,
                                          half_float::half(0), half_float::half(1));
    case pnk::ActivationTypeLinear:
      alphaParameter = (half_float::half)alpha(0);
      betaParameter = (half_float::half)beta(0);
      return alphaParameter * value + betaParameter;
    case pnk::ActivationTypeELU:
      alphaParameter = (half_float::half)alpha(0);
      return value < (half_float::half)0.0 ?
          (alphaParameter * (half_float::half)(std::exp(value) - 1)) : value;
    case pnk::ActivationTypeSoftsign:
      return value / (half_float::half)(1 + std::abs(value));
    case pnk::ActivationTypeSoftplus:
      return (half_float::half)std::log(1 + std::exp(value));
    case pnk::ActivationTypeParametricSoftplus:
      alphaParameter = (half_float::half)alpha(0);
      betaParameter = (half_float::half)beta(0);
      return alphaParameter * (half_float::half)std::log(1 + std::exp(betaParameter * value));
  }
}

cv::Mat PNKCalculateUnary(const cv::Mat &inputMatrix, pnk::UnaryType unaryType, float alpha,
                          float scale, float shift, float epsilon) {
  int rows = inputMatrix.rows;
  int columns = inputMatrix.cols;
  int channels = inputMatrix.channels();
  cv::Mat input = inputMatrix.reshape(1, rows * columns);
  cv::Mat1hf output = cv::Mat1hf::zeros(rows * columns, channels);

  for (int row = 0; row < rows; ++row) {
    for (int column = 0; column < columns; ++column) {
      for (int channel = 0; channel < channels; ++channel) {
        half_float::half value = input.at<half_float::half>(row * columns + column, channel);
        half_float::half result = PNKUnaryFunction(value, unaryType, alpha, scale, shift, epsilon);
        output.at<half_float::half>(row * columns + column, channel) = result;
      }
    }
  }

  cv::Mat outputMat = output.reshape(channels, rows);
  return outputMat;
}

half_float::half PNKUnaryFunction(half_float::half value, pnk::UnaryType unaryType, float alpha,
                                  float scale, float shift, float epsilon) {
  float floatValue = (float)value;
  floatValue = scale * floatValue + shift;

  switch (unaryType) {
    case pnk::UnaryTypeSqrt:
      return (half_float::half)sqrt(floatValue);
    case pnk::UnaryTypeRsqrt:
      return (half_float::half)(1. / sqrt(floatValue + epsilon));
    case pnk::UnaryTypeInverse:
      return (half_float::half)(1. / (floatValue + epsilon));
    case pnk::UnaryTypePower:
      return (half_float::half)std::pow(floatValue, alpha);
    case pnk::UnaryTypeExp:
      return (half_float::half)std::exp(floatValue);
    case pnk::UnaryTypeLog:
      return (half_float::half)std::log(floatValue);
    case pnk::UnaryTypeAbs:
      return (half_float::half)std::abs(floatValue);
    case pnk::UnaryTypeThreshold:
      return (half_float::half)std::max(alpha, floatValue);
    default:
      return value;
  }
}

NS_ASSUME_NONNULL_END
