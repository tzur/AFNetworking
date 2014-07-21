// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPropertyMacros.h"

#import "LTBrushEffect.h"

@class LTTexture;

/// @class LTBrushColorDynamicsEffect
///
/// A class representing a dynamic brush effect used by the \c LTBrush.
/// This class implements the color dynamics effect, allowing to dynamically control the color of
/// the brush as we paint.
///
/// @see http://www.photoshopessentials.com/basics/photoshop-brushes/brush-dynamics/
@interface LTBrushColorDynamicsEffect : LTBrushEffect

/// Returns an array of target colors based on the given array of normalized \c LTRotatedRects which
/// represent the (normalized) locations of the brush tips, and the given base color.
///
/// @note when the \c baseColorTexture property is set, the baseColor argument is discarded.
- (NSArray *)colorsFromRects:(NSArray *)rects baseColor:(UIColor *)baseColor;

/// Specifies a percentage by which the hue of the paint can vary in stroke.
/// Must be in range [0,1], default is 1.
@property (nonatomic) CGFloat hueJitter;
LTPropertyDeclare(CGFloat, hueJitter, HueJitter);

/// Specifies a percentage by which the saturation of the paint can vary in stroke.
/// Must be in range [0,1], default is 1.
@property (nonatomic) CGFloat saturationJitter;
LTPropertyDeclare(CGFloat, saturationJitter, SaturationJitter);

/// Specifies a percentage by which the brightness of the paint can vary in stroke.
/// Must be in range [0,1], default is 1.
@property (nonatomic) CGFloat brightnessJitter;
LTPropertyDeclare(CGFloat, brightnessJitter, BrightnessJitter);

/// When set, the effect will sample the base color from this texture according to the center of
/// each rect. When set to \nil, the base color will be used.
///
/// @note For performance reasons, this texture should be a memory mapped texture.
@property (strong, nonatomic) LTTexture *baseColorTexture;

// TODO:(amit) add the foreground/background jitter, and the purity control.

@end
