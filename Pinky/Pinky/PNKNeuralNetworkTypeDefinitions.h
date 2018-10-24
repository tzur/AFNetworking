// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

namespace pnk {

/// Padding types for operations dependant on padding such as convolution and pooling.
enum PaddingType : unsigned short {
  /// Output only contains pixels calculated from a region fully contained in the input.
  PaddingTypeValid,
  /// Output has the same size as input.
  PaddingTypeSame
};

/// Pooling types for \c PoolingKernelModel.
enum PoolingType : unsigned short {
  /// Output is equal to the maximum within the input filter window.
  PoolingTypeMax,
  /// Output is equal to the average within the input filter window.
  PoolingTypeAverage,
  /// Output is equal to the L2 norm within the input filter window.
  PoolingTypeL2
};

/// Valid activation types for \c ActivationKernelModel.
enum ActivationType : unsigned short {
  /// An identity activation. <tt>f(x) = x</tt>.
  ActivationTypeIdentity,
  /// An absolute function activation. <tt>f(x) = abs(x)</tt>.
  ActivationTypeAbsolute,
  /// A rectified linear unit (ReLU) activation. <tt>f(x) = max(0, x)</tt>.
  ActivationTypeReLU,
  /// A leaky rectified linear unit activation. <tt>f(x) = max(0, x) + alpha *
  /// min(0, x)</tt>.
  ActivationTypeLeakyReLU,
  /// A hyperbolic tangent activation. <tt>f(x) = (1 - exp(-2 * x)) / (1 + exp(-2 * x))</tt>.
  ActivationTypeTanh,
  /// A scaled hyperbolic tangent activation. <tt>f(x) = alpha * tanh(beta * x)</tt>.
  ActivationTypeScaledTanh,
  /// A sigmoid activation. <tt>f(x) = 1 / (1 + exp(-x))</tt>.
  ActivationTypeSigmoid,
  /// A hard sigmoid activation. <tt>f(x) = min(max(alpha * x + beta, 0), 1)</tt>.
  ActivationTypeSigmoidHard,
  /// A linear activation. <tt>f(x) = alpha * x + beta</tt>.
  ActivationTypeLinear,
  /// A parametrized rectified linear unit (PReLU) activation. This activation is similar to leaky
  /// ReLU only that it can be parametrized with a separate scaling and bias parameters per channel.
  /// For the ith channel <tt>f(x_i) = max(0, x_i) + alpha_i * min(0, x_i)</tt>.
  ActivationTypePReLU,
  /// An exponential linear unit (ELU) activation. <tt>f(x) = x > 0 ? x : alpha * (exp(x) - 1)</tt>.
  ActivationTypeELU,
  /// A softsign activation. <tt>f(x) = x / (1 + abs(x))</tt>.
  ActivationTypeSoftsign,
  /// A softplus activation. <tt>f(x) = log(1 + exp(x))</tt>.
  ActivationTypeSoftplus,
  /// A parametric softplus activation. <tt>f(x) = alpha * log(1 + exp(beta * x))</tt>.
  ActivationTypeParametricSoftplus
};

/// Valid unary function types for \c UnaryFunctionKernelModel.
enum UnaryType : unsigned short {
  /// max(alpha, x)
  UnaryTypeThreshold
};

} // namespace pnk
