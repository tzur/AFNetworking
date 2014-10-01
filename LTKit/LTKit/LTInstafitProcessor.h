// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

#import "LTProcessorFillMode.h"

@class LTTexture;

/// Instafit processor, used to place a non-square image on a square background. The placement is
/// controlled with translation, scaling and rotation. Non-square image can be optionally framed
/// with a border.
@interface LTInstafitProcessor : LTImageProcessor

/// Initializes with an input image, maximum dimension of the texture content is renderd to and an
/// output texture. The output texture must be a square.
- (instancetype)initWithInput:(LTTexture *)input contentMaxDimension:(CGFloat)dimension
                       output:(LTTexture *)output;

/// Background texture to display behind the \c input texture. The default background is a white 1x1
/// texture. Setting this to \c nil will return the default background to use.
@property (strong, nonatomic) LTTexture *background;

/// How the output should be filled with the background texture. The default value is
/// \c LTProcessorFillModeTile.
@property (nonatomic) LTProcessorFillMode fillMode;

/// Translation of the input texture on top of the background. The default value is \c (0, 0).
@property (nonatomic) CGPoint translation;

/// Uniform scaling of the input texture around its center. The default value is \c 1.
@property (nonatomic) CGFloat scaling;

/// Rotation, in radians, of the input texture on top of the background. The default value is \c 0.
@property (nonatomic) CGFloat rotation;

/// Color of the frame around the image. Should be in [0, 1] range. Default value is (0, 0, 0).
@property (nonatomic) LTVector3 frameColor;
LTPropertyDeclare(LTVector3, frameColor, FrameColor);

/// Width of the frame around the image. Should be in [0, 1] range. Default value is 0.
@property (nonatomic) CGFloat frameWidth;
LTPropertyDeclare(CGFloat, frameWidth, FrameWidth);

@end
