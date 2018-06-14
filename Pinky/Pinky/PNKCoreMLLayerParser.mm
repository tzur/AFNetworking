// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "PNKCoreMLLayerParser.h"

#import <LTEngine/LTOpenCVExtensions.h>

#import "PNKNeuralNetworkModel.h"
#import "PNKProtobufMacros.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import "Model.pb.h"
#import "NeuralNetwork.pb.h"
PNK_PROTOBUF_INCLUDE_END

NS_ASSUME_NONNULL_BEGIN

namespace cms = CoreML::Specification;

namespace pnk {

namespace {

  PaddingType paddingType(cms::ConvolutionLayerParams::ConvolutionPaddingTypeCase paddingType) {
  switch (paddingType) {
    case cms::ConvolutionLayerParams::kValid:
      return PaddingTypeValid;
    case cms::ConvolutionLayerParams::kSame:
      return PaddingTypeSame;
    default:
      LTParameterAssert(NO, @"Unsupported padding");
  }
}

PaddingType paddingType(cms::PoolingLayerParams::PoolingPaddingTypeCase paddingType) {
  switch (paddingType) {
    case cms::PoolingLayerParams::kValid:
      return PaddingTypeValid;
    case cms::PoolingLayerParams::kSame:
      return PaddingTypeSame;
    default:
      LTParameterAssert(NO, @"Unsupported padding");
  }
}

PoolingType poolingType(cms::PoolingLayerParams_PoolingType poolingType) {
  switch (poolingType) {
    case cms::PoolingLayerParams_PoolingType_MAX:
      return PoolingTypeMax;
    case cms::PoolingLayerParams_PoolingType_AVERAGE:
      return PoolingTypeAverage;
    case cms::PoolingLayerParams_PoolingType_L2:
      return PoolingTypeL2;
    default:
      LTParameterAssert(NO, @"Unsupported pooling type");
  }
}

cv::Mat createMatFromWeightParams(const cms::WeightParams &weightParams,
                                  int outputCVDepth = -1) {
  LTParameterAssert(outputCVDepth == CV_16F || outputCVDepth == CV_32F || outputCVDepth == -1,
                    @"Only CV_16F, CV_32F and -1 are supported values for outputCVDepth parameter, "
                    "got %d", outputCVDepth);
  if (weightParams.floatvalue().size()) {
    auto floatValue = weightParams.floatvalue();
    cv::Mat1f mat(1, floatValue.size());
    std::copy(floatValue.begin(), floatValue.end(), mat.begin());
    if (outputCVDepth == CV_16F) {
      cv::Mat1hf halfFloatMat;
      LTConvertMat(mat, &halfFloatMat, CV_16F);
      return halfFloatMat;
    } else {
      return mat;
    }
  } else if (weightParams.float16value().size()) {
    auto halfFloatValue = weightParams.float16value();
    cv::Mat1hf mat(1, (int)halfFloatValue.size() / sizeof(half_float::half));
    memcpy(mat.data, halfFloatValue.data(), halfFloatValue.size());
    if (outputCVDepth == CV_32F) {
      cv::Mat1f floatMat;
      LTConvertMat(mat, &floatMat, CV_32F);
      return floatMat;
    } else {
      return mat;
    }
  } else if (weightParams.rawvalue().size()) {
    LTParameterAssert(NO, @"Cannot read weights array from the rawvalue field");
  } else {
    return (outputCVDepth >= 0) ? cv::Mat(0, 0, outputCVDepth) : cv::Mat1f();
  }
}

/// CoreML serialization uses an OIHW order for convolution layer kernel weights while Metal uses
/// an OHWI order.
cv::Mat metalConvolutionWeightsFromCoreMLConvolutionParameters(
    const cms::ConvolutionLayerParams &convolutionParams) {
  const cv::Mat weights = createMatFromWeightParams(convolutionParams.weights());
  NSUInteger kernelChannels = (NSUInteger)convolutionParams.kernelchannels();
  NSUInteger outputFeatureChannels = (NSUInteger)convolutionParams.outputchannels();
  NSUInteger kernelHeight = (NSUInteger)convolutionParams.kernelsize(0);
  NSUInteger kernelWidth = (NSUInteger)convolutionParams.kernelsize(1);

  cv::Mat result(weights.rows, weights.cols, weights.depth());
  NSUInteger channelSize = kernelHeight * kernelWidth * kernelChannels;
  NSUInteger imageSize = kernelHeight * kernelWidth;
  for (NSUInteger outputChannel = 0; outputChannel < outputFeatureChannels ; ++outputChannel) {
    cv::Rect roi((int)(outputChannel * channelSize), 0, (int)channelSize, 1);
    cv::transpose(weights(roi).reshape(1, (int)kernelChannels),
                  result(roi).reshape(1, (int)imageSize));
  }

  return result;
}

} // anonymous namespace

#pragma mark -
#pragma mark Public methods
#pragma mark -

ImageScaleBiasModel createScaleBiasModel
    (const cms::NeuralNetworkImageScaler &imageScaler) {
  return ImageScaleBiasModel{
    .channelScale = imageScaler.channelscale(),
    .blueBias = imageScaler.bluebias(),
    .greenBias = imageScaler.greenbias(),
    .redBias = imageScaler.redbias(),
    .grayBias = imageScaler.graybias()
  };
}

ConvolutionKernelModel createConvolutionKernelModel
    (const cms::ConvolutionLayerParams &convolutionParams) {
  LTParameterAssert(convolutionParams.kernelsize_size() == 2, @"Kernel is %d, should be 2D",
                    convolutionParams.kernelsize_size());
  LTParameterAssert(convolutionParams.stride_size() == 2, @"Stride is %d, should be 2D",
                    convolutionParams.stride_size());
  LTParameterAssert(convolutionParams.dilationfactor_size() == 2, @"Dilation is %d, should be 2D",
                    convolutionParams.dilationfactor_size());
  LTParameterAssert(!convolutionParams.isdeconvolution() ||
                    convolutionParams.outputshape_size() == 2, @"Outputshape is %d, should be 2D",
                    convolutionParams.outputshape_size());
  LTParameterAssert(convolutionParams.hasbias() == convolutionParams.has_bias(),
                    @"Has bias is not consistent");
  LTParameterAssert(convolutionParams.has_weights(), @"Convolution model has no kernel weight "
                    "parameters");

  return ConvolutionKernelModel{
    .kernelHeight = (NSUInteger)convolutionParams.kernelsize(0),
    .kernelWidth = (NSUInteger)convolutionParams.kernelsize(1),
    .kernelChannels = (NSUInteger)convolutionParams.kernelchannels(),
    .groups = (NSUInteger)convolutionParams.ngroups(),
    .inputFeatureChannels = (NSUInteger)(convolutionParams.ngroups() *
                                         convolutionParams.kernelchannels()),
    .outputFeatureChannels = (NSUInteger)convolutionParams.outputchannels(),
    .strideY = (NSUInteger)convolutionParams.stride(0),
    .strideX = (NSUInteger)convolutionParams.stride(1),
    .dilationY = (NSUInteger)convolutionParams.dilationfactor(0),
    .dilationX = (NSUInteger)convolutionParams.dilationfactor(1),
    .deconvolutionOutputSize = convolutionParams.isdeconvolution() ?
        CGSizeMake(convolutionParams.outputshape(0),
                   convolutionParams.outputshape(1)) :
        CGSizeNull,
    .padding = paddingType(convolutionParams.ConvolutionPaddingType_case()),
    .isDeconvolution = convolutionParams.isdeconvolution(),
    .hasBias = convolutionParams.hasbias(),
    .kernelWeights = metalConvolutionWeightsFromCoreMLConvolutionParameters(convolutionParams),
    .biasWeights = convolutionParams.has_bias() ?
        createMatFromWeightParams(convolutionParams.bias(), CV_32F) : cv::Mat1f()
  };
}

PoolingKernelModel createPoolingKernelModel
    (const cms::PoolingLayerParams &poolingParams) {
  LTParameterAssert(poolingParams.kernelsize_size() == 2, @"Kernel is %d, should be 2D",
                    poolingParams.kernelsize_size());
  LTParameterAssert(poolingParams.stride_size() == 2, @"Stride is %d, should be 2D",
                    poolingParams.stride_size());

  return PoolingKernelModel{
    .padding = paddingType(poolingParams.PoolingPaddingType_case()),
    .pooling = poolingType(poolingParams.type()),
    .kernelHeight = (NSUInteger)poolingParams.kernelsize(0),
    .kernelWidth = (NSUInteger)poolingParams.kernelsize(1),
    .strideY = (NSUInteger)poolingParams.stride(0),
    .strideX = (NSUInteger)poolingParams.stride(1),
    .averagePoolExcludePadding = poolingParams.avgpoolexcludepadding(),
    .globalPooling = poolingParams.globalpooling(),
  };
}

ActivationKernelModel createActivationKernelModel(const cms::ActivationParams &activationParams) {
  switch (activationParams.NonlinearityType_case()) {
    case cms::ActivationParams::kLinear:
      return ActivationKernelModel{
        .activationType = ActivationTypeLinear,
        .alpha = cv::Mat1f(1, 1, activationParams.linear().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.linear().beta())
      };
    case cms::ActivationParams::kReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypeReLU
      };
    case cms::ActivationParams::kLeakyReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypeLeakyReLU,
        .alpha = cv::Mat1f(1, 1, activationParams.leakyrelu().alpha())
      };
    case cms::ActivationParams::kPReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypePReLU,
        .alpha = createMatFromWeightParams(activationParams.prelu().alpha(), CV_32F)
      };
    case cms::ActivationParams::kTanh:
      return ActivationKernelModel{
        .activationType = ActivationTypeTanh
      };
    case cms::ActivationParams::kScaledTanh:
      return ActivationKernelModel{
        .activationType = ActivationTypeScaledTanh,
        .alpha = cv::Mat1f(1, 1, activationParams.scaledtanh().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.scaledtanh().beta())
      };
    case cms::ActivationParams::kSigmoid:
      return ActivationKernelModel{
        .activationType = ActivationTypeSigmoid
      };
    case cms::ActivationParams::kSigmoidHard:
      return ActivationKernelModel{
        .activationType = ActivationTypeSigmoidHard,
        .alpha = cv::Mat1f(1, 1, activationParams.sigmoidhard().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.sigmoidhard().beta())
      };
    case cms::ActivationParams::kELU:
      return ActivationKernelModel{
        .activationType = ActivationTypeELU,
        .alpha = cv::Mat1f(1, 1, activationParams.elu().alpha())
      };
    case cms::ActivationParams::kSoftsign:
      return ActivationKernelModel{
        .activationType = ActivationTypeSoftsign
      };
    case cms::ActivationParams::kSoftplus:
      return ActivationKernelModel{
        .activationType = ActivationTypeSoftplus
      };
    case cms::ActivationParams::kParametricSoftplus:
      return ActivationKernelModel{
        .activationType = ActivationTypeParametricSoftplus,
        .alpha = createMatFromWeightParams(activationParams.parametricsoftplus().alpha(), CV_32F),
        .beta = createMatFromWeightParams(activationParams.parametricsoftplus().beta(), CV_32F)
      };
    default:
      LTParameterAssert(NO, @"Unsupported activation nonlinearity");
  }
}

NormalizationKernelModel createNormalizationKernelModel
    (const cms::BatchnormLayerParams &batchnormParams) {
  LTParameterAssert(batchnormParams.has_gamma(), @"Normalization model has no gamma");
  LTParameterAssert(batchnormParams.has_beta(), @"Normalization model has no beta");
  if (!batchnormParams.computemeanvar()) {
    LTParameterAssert(batchnormParams.has_mean(), @"Normalization model has no mean");
    LTParameterAssert(batchnormParams.has_variance(), @"Normalization model has no variance");
  }

  return NormalizationKernelModel{
    .inputFeatureChannels = (NSUInteger)batchnormParams.channels(),
    .computeMeanVar = batchnormParams.computemeanvar(),
    .instanceNormalization = batchnormParams.instancenormalization(),
    .epsilon = batchnormParams.epsilon(),
    .scale = createMatFromWeightParams(batchnormParams.gamma(), CV_32F),
    .shift = createMatFromWeightParams(batchnormParams.beta(), CV_32F),
    .mean = batchnormParams.computemeanvar() ? cv::Mat1f():
        createMatFromWeightParams(batchnormParams.mean(), CV_32F),
    .variance = batchnormParams.computemeanvar() ? cv::Mat1f() :
        createMatFromWeightParams(batchnormParams.variance(), CV_32F)
  };
}

NormalizationKernelModel createConditionalInstanceNormalizationKernelModel
    (const cms::CustomLayerParams &customLayerParams) {
  auto parameters = customLayerParams.parameters();
  auto weights = customLayerParams.weights();

  return NormalizationKernelModel{
    .inputFeatureChannels = (NSUInteger)parameters["channels"].intvalue(),
    .computeMeanVar = YES,
    .instanceNormalization = YES,
    .epsilon = (float)parameters["epsilon"].doublevalue(),
    .scale = createMatFromWeightParams(weights[0], CV_32F),
    .shift = createMatFromWeightParams(weights[1], CV_32F)
  };
}

} // namespace pnk

NS_ASSUME_NONNULL_END
