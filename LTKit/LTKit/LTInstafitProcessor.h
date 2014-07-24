// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTImageProcessor.h"

@class LTTexture;

/// Processor for the Instafit feature, allowing to place a non-square image on a square output,
/// with controllable tilable background.
@interface LTInstafitProcessor : LTImageProcessor

/// Initializes with an input image, mask (that will hide parts of the input image) and an output
/// texture. The output texture must be a square.
- (instancetype)initWithInput:(LTTexture *)input mask:(LTTexture *)mask output:(LTTexture *)output;

/// Background texture to display behind the \c input texture. The default background is a white 1x1
/// texture. Setting this to \nil will return the default background to use.
@property (strong, nonatomic) LTTexture *background;

/// Translation of the input texture on top of the background. The default value is \c (0, 0).
@property (nonatomic) CGPoint translation;

/// Uniform scaling of the input texture around its center. The default value is \c 1.
@property (nonatomic) float scaling;

/// Rotation, in radians, of the input texture on top of the background. The default value is \c 0.
@property (nonatomic) float rotation;

@end
