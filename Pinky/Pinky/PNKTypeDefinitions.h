// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

namespace pnk {

  /// Color transform to be applied on image.
  enum ColorTransformType : unsigned short {
    /// No transform.
    ColorTransformTypeNone,
    /// Duplicate 1 input channel (Y) into 3 output channels (RGB). If alpha channel presents - set
    /// it to 1.
    ColorTransformTypeYToRGBA,
    /// Convert the RGB channels to the luma (Y) channel using the BT.601 standard.
    ColorTransformTypeRGBAToY
  };

  /// Arithmetic operations.
  enum ArithmeticOperation : unsigned short {
    /// Addition.
    ArithmeticOperationAddition,
    /// Substraction.
    ArithmeticOperationSubstraction,
    /// Multiplication.
    ArithmeticOperationMultiplication,
    /// Division.
    ArithmeticOperationDivision
  };

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
