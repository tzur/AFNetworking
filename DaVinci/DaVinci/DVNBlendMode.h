// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Types of blend modes. See https://en.wikipedia.org/wiki/Blend_modes and
/// http://www.w3.org/TR/SVGCompositing/ for more details.
LTEnumDeclare(NSUInteger, DVNBlendMode,
  DVNBlendModeNormal,
  DVNBlendModeDarken,
  DVNBlendModeMultiply,
  DVNBlendModeHardLight,
  DVNBlendModeSoftLight,
  DVNBlendModeLighten,
  DVNBlendModeScreen,
  DVNBlendModeColorBurn,
  DVNBlendModeOverlay,
  DVNBlendModePlusLighter,
  DVNBlendModePlusDarker,
  DVNBlendModeSubtract
);

NS_ASSUME_NONNULL_END
