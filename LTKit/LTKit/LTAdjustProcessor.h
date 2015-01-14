// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// @class LTAdjustProcessor
///
/// This class tonally adjusts the image. The manipulations can be categorized into the four
/// following categories: luminance, color, details and split-tone.
/// Luminance / color separation is done with YIQ color space.
/// Details are boosted using CLAHE (Contrast Limited Adaptive Historgram Equalization).
@interface LTAdjustProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Luminance
#pragma mark -

/// Changes the brightness of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat brightness;
LTPropertyDeclare(CGFloat, brightness, Brightness);

/// Changes the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat contrast;
LTPropertyDeclare(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat exposure;
LTPropertyDeclare(CGFloat, exposure, Exposure);

/// Changes the additive offset of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat offset;
LTPropertyDeclare(CGFloat, offset, Offset);

#pragma mark -
#pragma mark Levels
#pragma mark -

/// Shifts black by blackPointShift. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat blackPointShift;
LTPropertyDeclare(CGFloat, blackPointShift, BlackPointShift);

/// Shifts white by whitePointShift. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat whitePointShift;
LTPropertyDeclare(CGFloat, whitePointShift, WhitePointShift);

#pragma mark -
#pragma mark Curves
#pragma mark -

/// LUT with 256 values in [0, 255] range representing a red channel curve.
@property (nonatomic) cv::Mat1b redCurve;

/// LUT with 256 values in [0, 255] range representing a green channel curve.
@property (nonatomic) cv::Mat1b greenCurve;

/// LUT with 256 values in [0, 255] range representing a blue channel curve.
@property (nonatomic) cv::Mat1b blueCurve;

/// LUT with 256 values in [0, 255] range representing a luminance curve.
/// This curve is applied after the per-channel curves.
@property (nonatomic) cv::Mat1b greyCurve;

#pragma mark -
#pragma mark Color
#pragma mark -

/// Changes the hue of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat hue;
LTPropertyDeclare(CGFloat, hue, Hue);

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;
LTPropertyDeclare(CGFloat, saturation, Saturation);

/// Changes the temperature of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat temperature;
LTPropertyDeclare(CGFloat, temperature, Temperature);

/// Changes the tint of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat tint;
LTPropertyDeclare(CGFloat, tint, Tint);

#pragma mark -
#pragma mark Details
#pragma mark -

/// Sharpens the image. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat sharpen;
LTPropertyDeclare(CGFloat, sharpen, Sharpen);

/// Controls the local contrast by changing the amplitude of the image details. Should be in [-1, 1]
/// range. Default value is 0.
@property (nonatomic) CGFloat details;
LTPropertyDeclare(CGFloat, details, Details);

/// Darkens/lightens the shadows, while preserving local contrast. Should be in [-1, 1] range.
/// Default value is 0.
@property (nonatomic) CGFloat shadows;
LTPropertyDeclare(CGFloat, shadows, Shadows);

/// Brightens the mid-range, while preserving local contrast. Should be in [0, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat fillLight;
LTPropertyDeclare(CGFloat, fillLight, FillLight);

/// Expands/compresses the highlights, while preserving local contrast. Should be in [-1, 1] range.
/// Default value is 0.
@property (nonatomic) CGFloat highlights;
LTPropertyDeclare(CGFloat, highlights, Highlights);

#pragma mark -
#pragma mark Split Toning
#pragma mark -

/// Changes the saturation of the darks. Should be in [0, 1] range. Default value is 0, it
/// corresponds to grey value, which will not affect the image.
@property (nonatomic) CGFloat darksSaturation;
LTPropertyDeclare(CGFloat, darksSaturation, DarksSaturation);

/// Changes the hue of the darks. Should be in [0, 1] range, which is mapped to [0, 360] circle of
/// hues. Default value is 0.
@property (nonatomic) CGFloat darksHue;
LTPropertyDeclare(CGFloat, darksHue, DarksHue);

/// Changes the saturation of the lights. Should be in [0, 1] range. Default value is 0, it
/// corresponds to grey, which will not affect the image.
@property (nonatomic) CGFloat lightsSaturation;
LTPropertyDeclare(CGFloat, lightsSaturation, LightsSaturation);

/// Changes the hue of the lights. Should be in [0, 1] range, which is mapped to [0, 360] circle of
/// hues. Default value is 0.
@property (nonatomic) CGFloat lightsHue;
LTPropertyDeclare(CGFloat, lightsHue, LightsHue);

/// Balances the effect of darks and highs in split-toning. Should be in [-1, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat balance;
LTPropertyDeclare(CGFloat, balance, Balance);

@end
