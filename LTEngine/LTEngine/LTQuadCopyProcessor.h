// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTOneShotImageProcessor.h"

@class LTQuad;

/// Processor for copying an input texture to a quad in an output texture. An implicit interpolation
/// will be triggered on the GPU depending on the min and mag filters of the input texture.
@interface LTQuadCopyProcessor : LTOneShotImageProcessor

/// Initializes with an input and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Quad to copy from the input texture. Quad is given in the input texture coordinate system. The
/// default value is an axis aligned (0, 0, input.width, input.height) rect.
@property (strong, nonatomic) LTQuad *inputQuad;

/// Quad to write the desired area in the input texture to. Quad is given in the output texture
/// coordinate system. The default value is an axis aligned (0, 0, output.width, output.height)
/// rect.
@property (strong, nonatomic) LTQuad *outputQuad;

@end
