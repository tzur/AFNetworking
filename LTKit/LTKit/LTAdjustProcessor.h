// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// @class LTAdjustProcessor
///
/// This class tonally adjust the image. The manipulations can be categorized into the three
/// following categories: luminance, color and details.
/// Luminance / color separation is done with YIQ color space.
/// Base / details separation is done with separable bilateral filter.
@interface LTAdjustProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Luminance Control.

/// Changes the brightness of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat brightness;

/// Changes the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat contrast;

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat exposure;

/// Changes the additive offset of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat offset;

/// Levels Control.

/// Remapes black to blackPoint. Components should be in [-1, 1] range. Default value is black
/// (0, 0, 0).
@property (nonatomic) GLKVector3 blackPoint;

/// Remapes white to whitePoint. Components should be in [0, 2] range. Default value is white
/// (1, 1, 1).
@property (nonatomic) GLKVector3 whitePoint;

/// Color Control.

/// Changes the saturation of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat saturation;

/// Changes the temperature of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat temperature;

/// Changes the tint of the image. Should be in [-1, 1] range. Default value is 0.
@property (nonatomic) CGFloat tint;

/// Local Contrast Control.

/// Controls the local contrast by changing the amplitude of the image details. Should be in [-1, 1]
/// range. Default value is 0.
@property (nonatomic) CGFloat details;

/// Brightens the shadows, while preserving local contrast. Should be in [0, 1] range. Default value
/// is 0.
@property (nonatomic) CGFloat shadows;

/// Brightens the mid-range, while preserving local contrast. Should be in [0, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat fillLight;

/// Compresses the highlights, while preserving local contrast. Should be in [0, 1] range. Default
/// value is 0.
@property (nonatomic) CGFloat highlights;

@end
