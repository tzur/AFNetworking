// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

/// @class LTAdjustProcessor
///
/// This class tonally adjusts the image. The manipulations can be categorized into the three
/// following categories: luminance, color and details.
/// Luminance / color separation is done with YIQ color space.
/// Base / details separation is done with separable bilateral filter.
@interface LTAdjustProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

#pragma mark -
#pragma mark Luminance
#pragma mark -

/// Changes the brightness of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, brightness, Brightness);

/// Changes the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, exposure, Exposure);

/// Changes the additive offset of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, offset, Offset);

#pragma mark -
#pragma mark Levels
#pragma mark -

/// Remapes black to blackPoint. Components should be in [-1, 1] range. Default value is black
/// (0, 0, 0).
LTDeclareProperty(GLKVector3, blackPoint, BlackPoint);

/// Remapes white to whitePoint. Components should be in [0, 2] range. Default value is white
/// (1, 1, 1).
LTDeclareProperty(GLKVector3, whitePoint, WhitePoint);

#pragma mark -
#pragma mark Color
#pragma mark -

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, saturation, Saturation);

/// Changes the temperature of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, temperature, Temperature);

/// Changes the tint of the image. Should be in [-1, 1] range. Default value is 0.
LTDeclareProperty(CGFloat, tint, Tint);

#pragma mark -
#pragma mark Details
#pragma mark -

/// Controls the local contrast by changing the amplitude of the image details. Should be in [-1, 1]
/// range. Default value is 0.
LTDeclareProperty(CGFloat, details, Details);

/// Brightens the shadows, while preserving local contrast. Should be in [0, 1] range. Default value
/// is 0.
LTDeclareProperty(CGFloat, shadows, Shadows);

/// Brightens the mid-range, while preserving local contrast. Should be in [0, 1] range. Default
/// value is 0.
LTDeclareProperty(CGFloat, fillLight, FillLight);

/// Compresses the highlights, while preserving local contrast. Should be in [0, 1] range. Default
/// value is 0.
LTDeclareProperty(CGFloat, highlights, Highlights);

@end
