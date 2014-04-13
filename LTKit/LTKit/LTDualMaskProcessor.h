// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// Available dual mask types.
typedef NS_ENUM(NSUInteger, LTDualMaskType) {
  LTDualMaskTypeRadial = 0,
  LTDualMaskTypeLinear = 1,
  LTDualMaskTypeDoubleLinear = 2,
};

/// @class LTDualMaskProcessor
///
/// This class creates dual masks. Dual mask is useful in scenarios where two adjustments have to
/// be applied in the same time. Regular mask conventionally apply maximum adjustment at 1 and
/// minimum at 0. Conversely, dual mask apply a maximum amount of the first adjustment (Blue) at 0
/// and a maximum amount of second adjustment (Red) and 1. Middle value 0.5 (neutral point) maps to
/// either neutral adjustment or an adjustment where two manipulations applied in the same amount.
///
/// Dual masks can be configured to have a different transition pattern around the center. On one
/// extreme, at certain distance from the center the mask will abruptly move from 0 to 1. At another
/// extreme, the mask will linearly transition from the center of the mask towards the outer edges
/// creating linear transition typical to regular masks.
///
/// It is not uncommon to use dual masks where either Red or Blue adjustment is identity, since this
/// gives the opportunity to customize the transition pattern.
///
/// Dual mask can be either radial, linear or double-linear. Center is neutral in linear and red in
/// radial and double linear.
@interface LTDualMaskProcessor : LTOneShotImageProcessor

/// Initializes the processor with output texture.
- (instancetype)initWithOutput:(LTTexture *)output;

/// Dual mask type to construct. Default is LTDualMaskTypeRadial.
@property (nonatomic) LTDualMaskType maskType;

/// Center of the mask on unit square [0, 1] x [0, 1]. Default value is (0.5, 0.5).
LTBoundedPrimitiveProperty(GLKVector2, center, Center);

/// Diameter of the mask is the length of the straight line between two neutral points through the
/// center. Should be in [0, 1] range. Default value is 0.5, so diameter of the red part is half the
/// unit square (or half of the smaller image dimension when corrected for aspect ratio).
/// @attention In case of linear mask type the width is zero by construction and this property
/// doesn't affect the mask.
LTBoundedPrimitiveProperty(CGFloat, diameter, Diameter);

/// Spread of the mask determines how smooth or abrupt the transition from Red to Blue part around
/// neutral point is. Should be in [-1, 1] range. -1 is smooth, 1 is abrupt. Default value it 0.
LTBoundedPrimitiveProperty(CGFloat, spread, Spread);

/// Angle in radians which tilts the mask.
/// @attention Radial mask is rotationally invariant, thus this parameters doesn't affect the mask.
LTBoundedPrimitiveProperty(CGFloat, angle, Angle)

@end
