// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

#import "LTProcessorFillMode.h"

@class LTRotatedRect;

/// Processor for copying rotated rect from an input texture to an output texture. The rects may be
/// of different size and rotation, thus an implicit interpolation will be triggered on the GPU
/// depending on the min and mag filters of the input texture.
@interface LTRectCopyProcessor : LTOneShotImageProcessor

/// Initializes with an input and output texture.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Rotated rect to copy from the input texture. Rect is given in the input texture coordinate
/// system. The default value is an axis aligned (0, 0, input.width, input.height) rect.
@property (nonatomic) LTRotatedRect *inputRect;

/// Rotated rect to write the desired area in the input texture to. Rect is given in the input
/// texture coordinate system. The default value is an axis aligned (0, 0, output.width,
/// output.height) rect.
@property (nonatomic) LTRotatedRect *outputRect;

/// How to fill the texture on \c outputRect if it has a different size than \c inputRect. The
/// default value is \c LTProcessorFillModeStretch.
@property (nonatomic) LTProcessorFillMode fillMode;

@end
