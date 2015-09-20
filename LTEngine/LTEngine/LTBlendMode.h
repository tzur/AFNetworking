// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Types of blend modes that are usable in mixer processors.
typedef NS_ENUM(NSUInteger, LTBlendMode) {
  LTBlendModeNormal = 0,
  LTBlendModeDarken,
  LTBlendModeMultiply,
  LTBlendModeHardLight,
  LTBlendModeSoftLight,
  LTBlendModeLighten,
  LTBlendModeScreen,
  LTBlendModeColorBurn,
  LTBlendModeOverlay,
  LTBlendModePlusLighter,
  LTBlendModePlusDarker
};
