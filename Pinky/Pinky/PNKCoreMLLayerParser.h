// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Lior Bar.

#import <optional>

NS_ASSUME_NONNULL_BEGIN

namespace CoreML {
  namespace Specification {
    class ActivationParams;
    class BatchnormLayerParams;
    class ConvolutionLayerParams;
    class CustomLayerParams;
    class InnerProductLayerParams;
    class NeuralNetworkImageScaler;
    class PoolingLayerParams;
    class UnaryFunctionLayerParams;
  }
}

namespace pnk {

struct ActivationKernelModel;
struct ConvolutionKernelModel;
struct ImageScaleBiasModel;
struct NormalizationKernelModel;
struct PoolingKernelModel;
struct UnaryFunctionKernelModel;

/// Returns an \c ImageScaleBiasModel with the values of the given \c imageScaler.
ImageScaleBiasModel createScaleBiasModel
  (const CoreML::Specification::NeuralNetworkImageScaler &imageScaler);

/// Returns a \c ConvolutionKernelModel with the values of the given \c convolutionParams.
ConvolutionKernelModel createConvolutionKernelModel
    (const CoreML::Specification::ConvolutionLayerParams &convolutionParams);

/// Returns a \c PoolingKernelModel with the values of the given \c poolingParams.
PoolingKernelModel createPoolingKernelModel
    (const CoreML::Specification::PoolingLayerParams &poolingParams);

/// Returns an \c ActivationKernelModel with the values of the given \c activationParams.
ActivationKernelModel createActivationKernelModel
    (const CoreML::Specification::ActivationParams &activationParams);

/// Returns an \c UnaryFunctionKernelModel with the values of the given \c unaryFunctionParams.
UnaryFunctionKernelModel createUnaryFunctionKernelModel
    (const CoreML::Specification::UnaryFunctionLayerParams &unaryFunctionParams);

/// Returns a \c NormalizationKernelModel with the values of the given \c batchnormParams.
NormalizationKernelModel createNormalizationKernelModel
    (const CoreML::Specification::BatchnormLayerParams &batchnormParams);

/// Returns a \c NormalizationKernelModel with the values of the given \c customLayerParams
/// representing a conditional instance normalization layer.
NormalizationKernelModel createConditionalInstanceNormalizationKernelModel
    (const CoreML::Specification::CustomLayerParams &customLayerParams);

} // namespace pnk

NS_ASSUME_NONNULL_END
