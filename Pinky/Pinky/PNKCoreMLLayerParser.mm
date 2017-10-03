// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import "PNKCoreMLLayerParser.h"

#import "PNKNeuralNetworkModel.h"
#import "PNKProtobufHelpers.h"
#import "PNKProtobufMacros.h"

PNK_PROTOBUF_INCLUDE_BEGIN
#import "Model.pb.h"
#import "NeuralNetwork.pb.h"
PNK_PROTOBUF_INCLUDE_END

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

namespace {

using CoreML::Specification::ActivationParams;
using CoreML::Specification::BatchnormLayerParams;
using CoreML::Specification::ConvolutionLayerParams;
using CoreML::Specification::InnerProductLayerParams;
using CoreML::Specification::PoolingLayerParams;

PaddingType paddingType(ConvolutionLayerParams::ConvolutionPaddingTypeCase paddingType) {
  switch (paddingType) {
    case ConvolutionLayerParams::kValid:
      return PaddingTypeValid;
    case ConvolutionLayerParams::kSame:
      return PaddingTypeSame;
    default:
      LTParameterAssert(NO, @"Unsupported padding");
  }
}

PaddingType paddingType(PoolingLayerParams::PoolingPaddingTypeCase paddingType) {
  switch (paddingType) {
    case PoolingLayerParams::kValid:
      return PaddingTypeValid;
    case PoolingLayerParams::kSame:
      return PaddingTypeSame;
    default:
      LTParameterAssert(NO, @"Unsupported padding");
  }
}

PoolingType poolingType(CoreML::Specification::PoolingLayerParams_PoolingType poolingType) {
  switch (poolingType) {
    case CoreML::Specification::PoolingLayerParams_PoolingType_MAX:
      return PoolingTypeMax;
    case CoreML::Specification::PoolingLayerParams_PoolingType_AVERAGE:
      return PoolingTypeAverage;
    case CoreML::Specification::PoolingLayerParams_PoolingType_L2:
      return PoolingTypeL2;
    default:
      LTParameterAssert(NO, @"Unsupported pooling type");
  }
}

/// CoreML serialization uses an OIHW order for convolution layer kernel weights while Metal uses
/// an OHWI order.
cv::Mat1f metalConvolutionWeightsFromCoreMLConvolutionParameters(
    const CoreML::Specification::ConvolutionLayerParams &convolutionParams) {
  const cv::Mat1f weights = createMat(convolutionParams.weights().floatvalue());
  NSUInteger inputFeatureChannels = (NSUInteger)(convolutionParams.ngroups() *
                                                 convolutionParams.kernelchannels());
  NSUInteger outputFeatureChannels = (NSUInteger)convolutionParams.outputchannels();
  NSUInteger kernelHeight = (NSUInteger)convolutionParams.kernelsize(1);
  NSUInteger kernelWidth = (NSUInteger)convolutionParams.kernelsize(0);

  cv::Mat1f result(weights.rows, weights.cols);
  NSUInteger channelSize = kernelHeight * kernelWidth * inputFeatureChannels;
  NSUInteger imageSize = kernelHeight * kernelWidth;
  for (NSUInteger outputChannel = 0; outputChannel < outputFeatureChannels ; ++outputChannel) {
    cv::Rect roi((int)(outputChannel * channelSize), 0, (int)channelSize, 1);
    cv::transpose(weights(roi).reshape(1, (int)inputFeatureChannels),
                  result(roi).reshape(1, (int)imageSize));
  }

  return result;
}

} // anonymous namespace

#pragma mark -
#pragma mark Public methods
#pragma mark -

ImageScaleBiasModel createScaleBiasModel
    (const CoreML::Specification::NeuralNetworkImageScaler &imageScaler) {
  return ImageScaleBiasModel{
    .channelScale = imageScaler.channelscale(),
    .blueBias = imageScaler.bluebias(),
    .greenBias = imageScaler.greenbias(),
    .redBias = imageScaler.redbias(),
    .grayBias = imageScaler.graybias()
  };
}

ConvolutionKernelModel createConvolutionKernelModel
    (const CoreML::Specification::ConvolutionLayerParams &convolutionParams) {
  LTParameterAssert(convolutionParams.kernelsize_size() == 2, @"Kernel is %d, should be 2D",
                    convolutionParams.kernelsize_size());
  LTParameterAssert(convolutionParams.stride_size() == 2, @"Stride is %d, should be 2D",
                    convolutionParams.stride_size());
  LTParameterAssert(convolutionParams.dilationfactor_size() == 2, @"Dilation is %d, should be 2D",
                    convolutionParams.dilationfactor_size());
  LTParameterAssert(convolutionParams.outputshape_size() == 2, @"Outputshape is %d, should be 2D",
                    convolutionParams.outputshape_size());
  LTParameterAssert(convolutionParams.hasbias() == convolutionParams.has_bias(),
                    @"Has bias is not consistent");
  LTParameterAssert(convolutionParams.has_weights(), @"Convolution model has no kernel weight "
                    "parameters");

  return ConvolutionKernelModel{
    .kernelWidth = (NSUInteger)convolutionParams.kernelsize(0),
    .kernelHeight = (NSUInteger)convolutionParams.kernelsize(1),
    .kernelChannels = (NSUInteger)convolutionParams.kernelchannels(),
    .groups = (NSUInteger)convolutionParams.ngroups(),
    .inputFeatureChannels = (NSUInteger)(convolutionParams.ngroups() *
                                         convolutionParams.kernelchannels()),
    .outputFeatureChannels = (NSUInteger)convolutionParams.outputchannels(),
    .strideX = (NSUInteger)convolutionParams.stride(0),
    .strideY = (NSUInteger)convolutionParams.stride(1),
    .dilationX = (NSUInteger)convolutionParams.dilationfactor(0),
    .dilationY = (NSUInteger)convolutionParams.dilationfactor(1),
    .deconvolutionOutputSize = CGSizeMake(convolutionParams.outputshape(0),
                                          convolutionParams.outputshape(1)),
    .padding = paddingType(convolutionParams.ConvolutionPaddingType_case()),
    .isDeconvolution = convolutionParams.isdeconvolution(),
    .hasBias = convolutionParams.hasbias(),
    .kernelWeights = metalConvolutionWeightsFromCoreMLConvolutionParameters(convolutionParams),
    .biasWeights = convolutionParams.has_bias() ? createMat(convolutionParams.bias().floatvalue()) :
        cv::Mat1f()
  };
}

PoolingKernelModel createPoolingKernelModel
    (const CoreML::Specification::PoolingLayerParams &poolingParams) {
  LTParameterAssert(poolingParams.kernelsize_size() == 2, @"Kernel is %d, should be 2D",
                    poolingParams.kernelsize_size());
  LTParameterAssert(poolingParams.stride_size() == 2, @"Stride is %d, should be 2D",
                    poolingParams.stride_size());

  return PoolingKernelModel{
    .padding = paddingType(poolingParams.PoolingPaddingType_case()),
    .pooling = poolingType(poolingParams.type()),
    .kernelWidth = (NSUInteger)poolingParams.kernelsize(0),
    .kernelHeight = (NSUInteger)poolingParams.kernelsize(1),
    .strideX = (NSUInteger)poolingParams.stride(0),
    .strideY = (NSUInteger)poolingParams.stride(1),
    .averagePoolExcludePadding = poolingParams.avgpoolexcludepadding(),
    .globalPooling = poolingParams.globalpooling(),
  };
}

ActivationKernelModel createActivationKernelModel(const ActivationParams &activationParams) {
  switch (activationParams.NonlinearityType_case()) {
    case ActivationParams::kLinear:
      return ActivationKernelModel{
        .activationType = ActivationTypeLinear,
        .alpha = cv::Mat1f(1, 1, activationParams.linear().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.linear().beta())
      };
    case ActivationParams::kReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypeReLU
      };
    case ActivationParams::kLeakyReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypeLeakyReLU,
        .alpha = cv::Mat1f(1, 1, activationParams.leakyrelu().alpha())
      };
    case ActivationParams::kThresholdedReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypeThresholdedReLU,
        .alpha = cv::Mat1f(1, 1, activationParams.thresholdedrelu().alpha())
      };
    case ActivationParams::kPReLU:
      return ActivationKernelModel{
        .activationType = ActivationTypePReLU,
        .alpha = createMat(activationParams.prelu().alpha().floatvalue())
      };
    case ActivationParams::kTanh:
      return ActivationKernelModel{
        .activationType = ActivationTypeTanh
      };
    case ActivationParams::kScaledTanh:
      return ActivationKernelModel{
        .activationType = ActivationTypeScaledTanh,
        .alpha = cv::Mat1f(1, 1, activationParams.scaledtanh().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.scaledtanh().beta())
      };
    case ActivationParams::kSigmoid:
      return ActivationKernelModel{
        .activationType = ActivationTypeSigmoid
      };
    case ActivationParams::kSigmoidHard:
      return ActivationKernelModel{
        .activationType = ActivationTypeSigmoidHard,
        .alpha = cv::Mat1f(1, 1, activationParams.sigmoidhard().alpha()),
        .beta = cv::Mat1f(1, 1, activationParams.sigmoidhard().beta())
      };
    case ActivationParams::kELU:
      return ActivationKernelModel{
        .activationType = ActivationTypeELU,
        .alpha = cv::Mat1f(1, 1, activationParams.elu().alpha())
      };
    case ActivationParams::kSoftsign:
      return ActivationKernelModel{
        .activationType = ActivationTypeSoftsign
      };
    case ActivationParams::kSoftplus:
      return ActivationKernelModel{
        .activationType = ActivationTypeSoftplus
      };
    case ActivationParams::kParametricSoftplus:
      return ActivationKernelModel{
        .activationType = ActivationTypeParametricSoftplus,
        .alpha = createMat(activationParams.parametricsoftplus().alpha().floatvalue()),
        .beta = createMat(activationParams.parametricsoftplus().beta().floatvalue())
      };
    default:
      LTParameterAssert(NO, @"Unsupported activation nonlinearity");
  }
}

AffineKernelModel createAffineKernelModel(const InnerProductLayerParams &innerproductParams) {
  LTParameterAssert(innerproductParams.hasbias() == innerproductParams.has_bias(),
                    @"Has bias is not consistent");
  LTParameterAssert(innerproductParams.has_weights(), @"Affine model has no kernel weight "
                    "parameters");

  return AffineKernelModel{
    .inputFeatureChannels = (NSUInteger)innerproductParams.inputchannels(),
    .outputFeatureChannels = (NSUInteger)innerproductParams.outputchannels(),
    .hasBias = innerproductParams.hasbias(),
    .kernelWeights = createMat(innerproductParams.weights().floatvalue()),
    .biasWeights = innerproductParams.has_bias() ?
        createMat(innerproductParams.bias().floatvalue()) : cv::Mat1f()
  };
}

NormalizationKernelModel createNormalizationKernelModel
    (const BatchnormLayerParams &batchnormParams) {
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
    .scale = createMat(batchnormParams.gamma().floatvalue()),
    .shift = createMat(batchnormParams.beta().floatvalue()),
    .mean = batchnormParams.computemeanvar() ? cv::Mat1f():
        createMat(batchnormParams.mean().floatvalue()),
    .variance = batchnormParams.computemeanvar() ? cv::Mat1f() :
        createMat(batchnormParams.variance().floatvalue())
  };
}

} // namespace pnk

NS_ASSUME_NONNULL_END
