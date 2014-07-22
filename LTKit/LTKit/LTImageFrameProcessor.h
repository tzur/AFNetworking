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
- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output
                        frame:(LTTexture *)frame frameType:(LTFrameType)frameType;

/// Factors the width of the frame. Should be in range of [0.5, 1.5], where 1.0, which is also the
/// default value, means no change to the input frame's width.
@property (nonatomic) CGFloat widthFactor;
LTPropertyDeclare(CGFloat, widthFactor, WidthFactor);

@end
