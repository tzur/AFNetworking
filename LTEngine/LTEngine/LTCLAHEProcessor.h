// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageProcessor.h"

@class LTTexture;

/// Converts RGB image to greyscale and applies Contrast Limited Adaptive Histogram Equalization on
/// it. For more details: Zuiderveld, Karel. "Contrast Limited Adaptive Histogram Equalization."
/// Graphic Gems IV. San Diego: Academic Press Professional, 1994. 474–485.
@interface LTCLAHEProcessor : LTImageProcessor

/// Initializes the processor with input and output textures. Output texture must have
/// \c LTGLPixelFormatR8Unorm pixel format.
- (instancetype)initWithInputTexture:(LTTexture *)inputTexture
                       outputTexture:(LTTexture *)outputTexture;

@end
