// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

@class LTRotatedRect;

/// Processor for compositing source and target region of interest into the output texture, by
/// mixing between the target texture and the source + membrane values using the mask. The output
/// texture will only be updated inside the given \c targetRect.
@interface LTPatchCompositorProcessor : LTOneShotImageProcessor

/// Initializes with a \c source, \c target, \c membrane, \c mask and \c output textures. The output
/// texture must be of the same size as the target texture.
- (instancetype)initWithSource:(LTTexture *)source target:(LTTexture *)target
                      membrane:(LTTexture *)membrane mask:(LTTexture *)mask
                        output:(LTTexture *)output;

/// Region of interest in the source texture, defined in source texture coordinates.
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Region of interest in the target texture, defined in target texture coordinates.
@property (strong, nonatomic) LTRotatedRect *targetRect;

@end
