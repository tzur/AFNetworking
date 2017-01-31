// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNBlendMode.h"

NS_ASSUME_NONNULL_BEGIN

LTEnumImplement(NSUInteger, DVNBlendMode,
  DVNBlendModeNormal,
  DVNBlendModeDarken,
  DVNBlendModeMultiply,
  DVNBlendModeHardLight,
  DVNBlendModeSoftLight,
  DVNBlendModeLighten,
  DVNBlendModeScreen,
  DVNBlendModeColorBurn,
  DVNBlendModeOverlay,
  DVNBlendModeAddition
);

NS_ASSUME_NONNULL_END
