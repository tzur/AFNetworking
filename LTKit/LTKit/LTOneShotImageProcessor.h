// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTIterativeImageProcessor.h"

/// @class LTOneShotImageProcessor
///
/// Processes a single image input with a single processing iteration, and returns a single output.
@interface LTOneShotImageProcessor : LTGPUImageProcessor <LTSubimageProcessing>

/// Initializes with a program, a single input texture and a single output texture.
- (instancetype)initWithProgram:(LTProgram *)program input:(LTTexture *)input
                      andOutput:(LTTexture *)output;

/// Initializes with a program, a source texture (which defines the coordinate system for
/// processing), additional input auxiliary textures and an output texture.
- (instancetype)initWithProgram:(LTProgram *)program sourceTexture:(LTTexture *)sourceTexture
              auxiliaryTextures:(NSDictionary *)auxiliaryTextures andOutput:(LTTexture *)output;

/// Size of the input texture or the source texture, if there are auxiliary textures available.
@property (readonly, nonatomic) CGSize inputSize;

/// Size of the output texture.
@property (readonly, nonatomic) CGSize outputSize;

/// Output texture of the processor.
@property (readonly, nonatomic) LTTexture *outputTexture;

/// Input texture of the processor.
@property (readonly, nonatomic) LTTexture *inputTexture;

@end
