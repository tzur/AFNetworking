// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#include "PNKNeuralNetworkTypeDefinitions.h"

#include <metal_stdlib>

using namespace metal;

namespace pnk {
  /// Calculates the activation of \c value with given \c activationType, \c alpha and \beta. The
  /// calculation is done for 4 feature channels together. \c arrayIndex must equal the index of the
  /// texture to which the \c value belongs in a texture array.
  half4 ActivatedValue(half4 value, ushort activationType, constant half4 *alpha,
                       constant half4 *beta, ushort arrayIndex);
} // namespace pnk
