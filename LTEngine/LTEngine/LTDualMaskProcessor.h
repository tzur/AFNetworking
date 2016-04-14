// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Available dual mask types.
typedef NS_ENUM(NSUInteger, LTDualMaskType) {
  LTDualMaskTypeRadial = 0,
  LTDualMaskTypeLinear = 1,
  LTDualMaskTypeDoubleLinear = 2,
  LTDualMaskTypeConstant = 3,
};

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
/// Dual mask can be either radial, linear, double-linear or constant. Center is neutral in linear
/// and red in radial and double linear. Constant is a special mode where the entire mask is red (or
/// blue (if \c invert is \c YES).
@interface LTDualMaskProcessor : LTOneShotImageProcessor

/// Initializes the processor with output texture.
- (instancetype)initWithOutput:(LTTexture *)output;

/// Dual mask type to construct. Default is LTDualMaskTypeRadial.
@property (nonatomic) LTDualMaskType maskType;

/// Center of the mask in coordinates of the output image, aka "pixel coordinates". Despite the
/// relation to pixels, values in this coordinate system doesn't have to be integer. Default value
/// is (0, 0). Range is unbounded.
@property (nonatomic) LTVector2 center;

/// Diameter of the mask is the length in pixels of the straight line between two neutral points
/// through the center. Range is unbounded. Default value is 0.
/// @attention In case of linear mask type the width is zero by construction and this property
/// doesn't affect the mask.
@property (nonatomic) CGFloat diameter;

/// Spread of the mask determines how smooth or abrupt the transition from Red to Blue part around
/// neutral point is. Should be in [-1, 1] range. -1 is smooth, 1 is abrupt. Default value it 0.
@property (nonatomic) CGFloat spread;
LTPropertyDeclare(CGFloat, spread, Spread);

/// Stretch factor of the mask along the direction vector specified by \c angle. Must be in
/// <tt>[0.1, 10]</tt> range. Default value is \c 1.
///
/// @attention Only radial mask is affected by this parameter since every other mask is scaling
/// invariant along the direction vector specified by \c angle. A value of \c 1 yields a mask in
/// form of circle, while values different from \c 1 yield a mask in form of a general ellipse.
@property (nonatomic) CGFloat stretch;
LTPropertyDeclare(CGFloat, stretch, Stretch);

/// Counterclockwise rotation angle in radians which tilts the mask. Default value is 0.
/// @attention Radial mask is rotationally invariant, thus this parameters doesn't affect the mask.
@property (nonatomic) CGFloat angle;

/// \c YES if the mask should be inverted. Default value is \c NO.
@property (nonatomic) BOOL invert;
LTPropertyDeclare(BOOL, invert, Invert);

@end
