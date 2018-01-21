// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

namespace pnk {

/// Structure that stores coefficients used by Metal to calculate sampling coordinates.
struct SamplingCoefficients {
  /// X-coordinate scale.
  float scaleX;
  /// Y-coordinate scale.
  float scaleY;
  /// X-coordinate bias.
  float biasX;
  /// Y-coordinate bias.
  float biasY;
};

} // namespace pnk
