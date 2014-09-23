// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

/// Processor used to composite a mask on top of an input image. The mask is assumed to be a single
/// channel image (where \c 0 marks masked area and \c 1 marks an unmasked area), allowing its
/// [0,1] grayscale color to be replaced with an RGB color using the \c maskColor property.
/// The opacity of the mask on top of the image can also be controlled, via the alpha value of the
/// \c maskColor.
@interface LTMaskOverlayProcessor : LTOneShotImageProcessor

/// Initializes with an image, its mask and an output image that will contain the mask composited
/// over the image, after processing.
- (instancetype)initWithImage:(LTTexture *)image mask:(LTTexture *)mask output:(LTTexture *)output;

/// Color of the mask to display on top of the input image. The alpha component is used to control
/// the opacity of the mask in a multiplicative way, meaning that the final color of the output will
/// be:
/// @code
/// (1 - (1 - mask.r) * maskColor.a) * image.rgb + ((1 - mask.r) * maskColor.a) * maskColor.rgb
/// @endcode
/// The default value is red color with alpha of 0.5: (1, 0, 0, 0.5).
@property (nonatomic) LTVector4 maskColor;

@end
