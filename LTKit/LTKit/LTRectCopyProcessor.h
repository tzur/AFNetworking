// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOneShotImageProcessor.h"

@class LTRotatedRect;

/// How to fill the texture on the output rect if is has a different size than the input.
typedef NS_ENUM(NSUInteger, LTRectCopyTexturingMode) {
  /// Stretch texture from input rect using the current texture interpolation method.
  LTRectCopyTexturingModeStretch = 0,
  /// Tile texture from input rect across the output rect. No stretching is done.
  LTRectCopyTexturingModeTile
};

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
/// default value is \c LTRectCopyTextureModeStretch.
@property (nonatomic) LTRectCopyTexturingMode texturingMode;

@end
