// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include "PNKActivation.metal.h"

namespace pnk {

half4 ActivatedValue(half4 value, ushort activationType, constant half4 *alpha,
                     constant half4 *beta, ushort arrayIndex) {
  switch ((pnk::ActivationType)activationType) {
    case pnk::ActivationTypeIdentity:
      return value;
    case pnk::ActivationTypeAbsolute:
      return abs(value);
    case pnk::ActivationTypeReLU:
      return max(value, 0.0h);
    case pnk::ActivationTypeLeakyReLU:
      return select(alpha[0][0] * value, value, value > 0.0h);
    case pnk::ActivationTypeTanh:
      return tanh(value);
    case pnk::ActivationTypeScaledTanh:
      return alpha[0][0] * tanh(beta[0][0] * value);
    case pnk::ActivationTypeSigmoid:
      return  1 / (1 + exp(-value));
    case pnk::ActivationTypeSigmoidHard:
      return  clamp(alpha[0][0] * value + beta[0][0], 0.0h, 1.0h);
    case pnk::ActivationTypeLinear:
      return alpha[0][0] * value + beta[0][0];
    case pnk::ActivationTypePReLU:
      return select(alpha[arrayIndex] * value, value, value > 0.0h);
    case pnk::ActivationTypeELU:
      return select(alpha[0][0] * (exp(value) - 1), value, value > 0.0h);
    case pnk::ActivationTypeSoftsign:
      return value / (1 + abs(value));
    case pnk::ActivationTypeSoftplus:
      return log(1 + exp(value));
    case pnk::ActivationTypeParametricSoftplus:
      return alpha[0][0] * log(1 + exp(beta[0][0] * value));
  }
}
} // namespace pnk
