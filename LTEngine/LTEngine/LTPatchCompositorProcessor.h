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

/// Region of interest in the source texture, defined in source texture coordinates. The default
/// value is an axis aligned (0, 0, source.width, source.height) rect.
@property (strong, nonatomic) LTRotatedRect *sourceRect;

/// Region of interest in the target texture, defined in target texture coordinates. The default
/// value is an axis aligned (0, 0, target.width, target.height) rect.
@property (strong, nonatomic) LTRotatedRect *targetRect;

/// Opacity of the source texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat sourceOpacity;
LTPropertyDeclare(CGFloat, sourceOpacity, SourceOpacity);

@end
