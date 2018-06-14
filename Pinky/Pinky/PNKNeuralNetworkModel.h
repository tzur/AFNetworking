// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import <experimental/optional>

#import "PNKNeuralNetworkOperationsModel.h"

NS_ASSUME_NONNULL_BEGIN

namespace pnk {

#pragma mark -
#pragma mark Neural Network model
#pragma mark -

/// Model representing a neural network. This model provides access to the various parameters of the
/// neural network. This model supports a single preprocessing operation per network. Other
/// operations are not limited in number. All operations should have distinct names to differentiate
/// them not only within operation type but also between operation types.
struct NeuralNetworkModel {
  /// Model for scaling and biasing the image, if needed.
  std::experimental::optional<ImageScaleBiasModel> scaleBiasModel;

  /// Models of convolution kernels in the network, mapped by name.
  std::unordered_map<std::string, ConvolutionKernelModel> convolutionKernels;

  /// Models of pooling kernels in the network, mapped by name.
  std::unordered_map<std::string, PoolingKernelModel> poolingKernels;

  /// Models of activation kernels in the network, mapped by name.
  std::unordered_map<std::string, ActivationKernelModel> activationKernels;

  /// Models of normalization kernels in the network, mapped by name.
  std::unordered_map<std::string, NormalizationKernelModel> normalizationKernels;

  /// Metadata of the network model, mapped by name.
  std::unordered_map<std::string, std::string> networkMetadata;
};

} // namespace pnk

NS_ASSUME_NONNULL_END
