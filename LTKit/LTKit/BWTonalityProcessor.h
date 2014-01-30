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

///
@property (nonatomic) LTColorGradient *colorGradient;

///
@property (nonatomic) CGFloat brightness;

///
@property (nonatomic) CGFloat contrast;

///
@property (nonatomic) CGFloat exposure;

///
@property (nonatomic) CGFloat structure;

@end
