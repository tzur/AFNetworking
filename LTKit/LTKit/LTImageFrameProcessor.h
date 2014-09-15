// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Shabtay.

#import "LTOneShotImageProcessor.h"

/// Supported types of frames, categorized by square-to-rectangle mapping modes:
/// 1. Stretching the central part of the longer dimension.
/// 2. Repeating the central part of the longer dimension integer number of times.
/// 3. Fitting the square frame in the middle of the image rectangle.
typedef NS_ENUM(NSUInteger, LTFrameType) {
  LTFrameTypeStretch = 0,
  LTFrameTypeRepeat,
  LTFrameTypeFit
};

/// Creates framed image using an input image and a frame asset. The frame's width can be modified
/// to being narrower or wider.
@interface LTImageFrameProcessor : LTOneShotImageProcessor

/// Initializes the processor with input texture, which will have a frame added to it as the output.
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output;

/// Sets the frame texture and frame type. Frame and frame type always go together.
- (void)setFrame:(LTTexture *)frame andType:(LTFrameType)frameType;

/// Factors the width of the frame. Should be in [0.75, 1.5] range. The default value is 1.0,
/// which means no change to the input frame's width.
@property (nonatomic) CGFloat widthFactor;
LTPropertyDeclare(CGFloat, widthFactor, WidthFactor);

/// Color of the frame. Components should be in [0, 1] range. Default color is (0, 0, 0).
@property (nonatomic) LTVector3 color;
LTPropertyDeclare(LTVector3, color, Color);

/// Determines the color interpolation with the original color of the frame. In the range of
/// [0.0, 1.0]. The default value is 0.0, which means no change to the input frame's color.
@property (nonatomic) CGFloat colorAlpha;
LTPropertyDeclare(CGFloat, colorAlpha, ColorAlpha);

@end
