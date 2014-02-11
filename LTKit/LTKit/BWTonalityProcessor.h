// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

@class LTColorGradient;

/// @class BWTonalityProcessor
///
/// Convert RGB image to BW (black and white). Tune the tonal characteristics of the result.
/// This class doesn't handle additional content that can be added to the image, such as noise,
/// texture, vignetting patterns and frames.
@interface BWTonalityProcessor : LTOneShotImageProcessor

/// Initialize the processor with input texture to be converted to BW and the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Color filter is a triplet that weights the contribution of each color channel during the
/// conversion process.
@property (nonatomic) GLKVector3 colorFilter;

/// Maps greyscale values to color in order to create a certain tint to a final result.
@property (strong, nonatomic) LTColorGradient *colorGradient;

/// Brightens the image. Should be in [-1 1] range.
@property (nonatomic) CGFloat brightness;

/// Increases the global contrast of the image. Should be in [0 2] range.
@property (nonatomic) CGFloat contrast;

/// Changes the exposure of the image. Should be in [0 2] range.
@property (nonatomic) CGFloat exposure;

/// Increases the local contrast of the image. Should be in [0 4] range.
@property (nonatomic) CGFloat structure;

@end
