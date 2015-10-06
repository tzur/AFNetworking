// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTDualMaskProcessor.h"

/// Rendering modes of the processor.
typedef NS_ENUM(NSUInteger, LTColorRangeRenderingMode) {
  /// Render the image with the manipulation applied.
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
#pragma mark Spatial Mask
#pragma mark -

/// Dual mask type to construct. Default is LTDualMaskTypeRadial.
@property (nonatomic) LTDualMaskType maskType;

/// Center of the mask in coordinates of the output image, aka "pixel coordinates". Despite the
/// relation to pixels, values in this coordinate system don't have to be integers.
/// Default value of the center is (0, 0). Range is unbounded.
@property (nonatomic) LTVector2 center;

/// Diameter of the mask is the length in pixels of the straight line between two neutral points
/// through the center. Range is unbounded. Default value is 0.
/// @attention In case of linear mask type the width is zero by construction and this property
/// doesn't affect the mask.
@property (nonatomic) CGFloat diameter;

/// Spread of the mask determines how smooth or abrupt the transition from Red to Blue part around
/// neutral point is. Should be in [-1, 1] range. 1 is smooth, -1 is abrupt. Default value is 0.
@property (nonatomic) CGFloat spread;
LTPropertyDeclare(CGFloat, spread, Spread);

/// Counterclockwise angle in radians which tilts the mask. Default value is 0.
/// @attention Radial mask is rotationally invariant, thus this parameters doesn't affect the mask.
@property (nonatomic) CGFloat angle;

#pragma mark -
#pragma mark Range Mask
#pragma mark -

/// Color at the \c center location of the input texture which is used for range attenuation. Range
/// attenuation assigns lower values to pixels that are dissimilar from \c rangeColor.
@property (readonly, nonatomic) LTVector3 rangeColor;

/// Fuzziness of the mask determines how inclusive the range attenuation is. For higher values, the
/// mask will affect pixels further away from \c rangeColor. Should be in [-1, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat fuzziness;
LTPropertyDeclare(CGFloat, fuzziness, Fuzziness);

/// \c YES if range attenuation should be disabled. In this case the result is completely determined
/// by the spatial attenuation controlled by the spatial mask parameters. Default value is \c NO.
@property (nonatomic) BOOL disableRangeAttenuation;

/// Sets the rendering mode of the processor. Default value is \c LTColorRangeRenderingModeImage.
@property (nonatomic) LTColorRangeRenderingMode renderingMode;

/// Color of the mask when \c renderingMode is \c LTColorRangeRenderingModeMaskOverlay. Components
/// should be in [0, 1] range. Default value is (1, 0, 0).
@property (nonatomic) LTVector3 maskColor;
LTPropertyDeclare(LTVector3, maskColor, MaskColor);

#pragma mark -
#pragma mark Adjustment
#pragma mark -

/// Changes the exposure of the image under the current mask. Should be in [-1, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat exposure;
LTPropertyDeclare(CGFloat, exposure, Exposure);

/// Changes the contrast of the image under the current mask. Should be in [-1, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat contrast;
LTPropertyDeclare(CGFloat, contrast, Contrast);

/// Changes the saturation of the image under the current mask. Should be in [-1, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

/// Changes the hue of the image under the current mask. Should be in [-1, 1] range. Default value
/// is 0.
@property (nonatomic) CGFloat hue;
LTPropertyDeclare(CGFloat, hue, Hue);

@end
