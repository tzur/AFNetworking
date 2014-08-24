// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// Rendering modes of the processor.
typedef NS_ENUM(NSUInteger, LTColorRangeRenderingMode) {
  /// Render the image with the manipulation allied.
  LTColorRangeRenderingModeImage = 0,
  /// Render selection mask.
  LTColorRangeRenderingModeMask,
  /// Render selection mask superimposed on the image.
  LTColorRangeRenderingModeMaskOverlay,
};

/// LTColorRangeAdjustProcessor manipulates hue, saturation and luminance of the color range defined
/// by the user.
@interface LTColorRangeAdjustProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Red
#pragma mark -

/// Color that is used to construct a mask that defines a color range upon which tonal manipulation
/// is applied. Components should be in [-1, 1] range. Default value is green (0, 1, 0).
@property (nonatomic) LTVector3 rangeColor;
LTPropertyDeclare(LTVector3, rangeColor, RangeColor);

/// Fuzziness of the mask determines how inclusive the mask is. For higher values, the mask will
/// affect pixels further away from \c maskColor. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat fuzziness;
LTPropertyDeclare(CGFloat, fuzziness, Fuzziness);

/// Changes the saturation of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

/// Changes the luminance of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat luminance;
LTPropertyDeclare(CGFloat, luminance, Luminance);

/// Changes the hue of the reds. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat hue;
LTPropertyDeclare(CGFloat, hue, Hue);

/// Sets the rendering mode of the processor. Default value is LTColorRangeRenderingModeImage.
@property (nonatomic) LTColorRangeRenderingMode renderingMode;

@end
