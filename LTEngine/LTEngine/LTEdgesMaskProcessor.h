// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Creates an edges image that can be used as a mask in more complex image processing algorithms,
/// such as NPR. The result of the computation at each pixel equals to: abs(dx) + abs(dy).
@interface LTEdgesMaskProcessor : LTImageProcessor

/// Initializes the processor with input texture to be adjusted and output texture. The output
/// texture can be either \c LTGLFormatRed or \c LTGLFormatRGBA, and the output will be
/// either the luminance or rgb differences according to it.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
