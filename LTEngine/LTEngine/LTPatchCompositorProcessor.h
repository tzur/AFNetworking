// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

@class LTQuad;

/// Processor for compositing source and target region of interest into the output texture, by
/// mixing between the target texture and the source + membrane values using the mask. The output
/// texture will only be updated inside the given \c targetQuad.
@interface LTPatchCompositorProcessor : LTOneShotImageProcessor

/// Initializes with a \c source, \c target, \c membrane, \c mask and \c output textures. The output
/// texture must be of the same size as the target texture.
- (instancetype)initWithSource:(LTTexture *)source target:(LTTexture *)target
                      membrane:(LTTexture *)membrane mask:(LTTexture *)mask
                        output:(LTTexture *)output;

/// Region of interest in the source texture, defined in source texture coordinates. The default
/// value is an axis aligned (0, 0, source.width, source.height) rect.
@property (strong, nonatomic) LTQuad *sourceQuad;

/// Region of interest in the target texture, defined in target texture coordinates. The default
/// value is an axis aligned (0, 0, target.width, target.height) rect.
@property (strong, nonatomic) LTQuad *targetQuad;

/// Opacity of the source texture in the range [0, 1]. Default value is \c 1.
@property (nonatomic) CGFloat sourceOpacity;
LTPropertyDeclare(CGFloat, sourceOpacity, SourceOpacity);

/// \c YES if the \c sourceQuad should be used in a mirrored way. The mirroring is performed along
/// the vertical line with <tt>x = 0.5</tt>, in texture coordinate space.
@property (nonatomic) BOOL flip;
LTPropertyDeclare(BOOL, flip, Flip);

/// Interpolation factor used to compute the strength of source smoothing. If \c 1, a fully smoothed
/// version of source is used, yielding a seamless patching effect. If \c 0, the source is used directly,
/// without any smoothing. Default value is \c 1.
@property (nonatomic) CGFloat smoothingAlpha;
LTPropertyDeclare(CGFloat, smoothingAlpha, SmoothingAlpha);

@end
