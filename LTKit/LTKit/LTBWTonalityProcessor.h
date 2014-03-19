// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

#import "LTPropertyMacros.h"

@class LTColorGradient;

/// @class LTBWTonalityProcessor
///
/// Converts RGB image to BW (black and white). Tunes the tonal characteristics of the result.
/// This class doesn't handle additional content that can be added to the image, such as noise,
/// texture, vignetting patterns and frames.
@interface LTBWTonalityProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture to be converted to BW and the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Color filter is a triplet that weights the contribution of each color channel during the
/// conversion process. Color components should be in [0, 1] range. An attempt to pass the black
/// color (all components are zero) will raise an exception.
/// Default value is the NTSC conversion triplet (0.299, 0.587, 0.114).
@property (nonatomic) GLKVector3 colorFilter;

/// RGBA texture with one row and at most 256 columns that defines greyscale to color mapping.
/// This LUT is used to colorize (add tint) to the BW conversion. Default value is an identity
/// mapping.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// Brightens the image. Should be in [-1 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, brightness, Brightness);

/// Increases the global contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, contrast, Contrast);

/// Changes the exposure of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, exposure, Exposure);

/// Changes the offset of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, offset, Offset);

/// Increases the local contrast of the image. Should be in [-1, 1] range. Default value is 0.
LTBoundedPrimitiveProperty(CGFloat, structure, Structure);

@end
