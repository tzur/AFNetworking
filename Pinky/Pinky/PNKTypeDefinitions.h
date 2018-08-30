// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Gershon Hochman.

#import "PNKDefines.h"

#if PNK_METAL_COMPILER
  namespace pnk_simd = metal;
#else
  namespace pnk_simd = simd;
#endif

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

  /// Structure that stores rectangle coordinates.
  template<typename T> struct Rect {
    /// Origin of the rectangle.
    T origin;
    /// Size of the rectangle.
    T size;
  };

  typedef Rect<pnk_simd::float2> Rect2f;
  typedef Rect<pnk_simd::uint2> Rect2ui;

} // namespace pnk
