// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Processes an input image using edge-avoiding wavelets, with support to up 4 luminance outputs.
@interface LTEAWProcessor : LTImageProcessor

/// Initializes with an input RGB texture and an output texture, containing up to 4 different
/// luminance outputs at each channel. The number of outputs is controlled by the number of channels
/// of the given output texture (hence, for a single output, pass a red texture).
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Factor controlling the amount of compression that will be applied to the input's texture
/// details. The default value is (1, 1, 1, 1), which will produce no effect. This processor is
/// capable of producing up to 4 different outputs for 4 different given compression factors. If
/// less outputs are requested, only the first components in the given vector will be considered.
@property (nonatomic) LTVector4 compressionFactor;

@end
