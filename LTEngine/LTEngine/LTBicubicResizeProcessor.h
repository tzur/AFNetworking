// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTOneShotImageProcessor.h"

/// Bicubic resizing processor. Upsamples or downsamples the input image to the dimensions of
/// the output image.
///
/// OpenGL ES 2.0 level GPU architecture doesn't allow to use bicubic texture sampler.
/// The smoothest hardware supported option is bilinear interpolation, which is not smooth enough
/// in some scenarios. This class offers a smoother and more costly bicubic interpolation.
@interface LTBicubicResizeProcessor : LTOneShotImageProcessor

/// Initialize the processor using the input and output textures. The resizing scaling factor is
/// implicitly determined by the ratio between the sizes of the textures.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

@end
