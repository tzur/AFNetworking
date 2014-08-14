// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTGPUImageProcessor.h"

#import "LTPartialProcessing.h"
#import "LTScreenProcessing.h"

@protocol LTProgramFactory;

/// @class LTOneShotImageProcessor
///
/// Processes a single image input with a single processing iteration, and returns a single output.
@interface LTOneShotImageProcessor : LTGPUImageProcessor <LTPartialProcessing, LTScreenProcessing>

/// Initializes with vertex and fragment shaders sources, a single input texture and a single output
/// texture.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                               input:(LTTexture *)input andOutput:(LTTexture *)output;

/// Initializes with vertex and fragment shaders sources, a source texture (which defines the
/// coordinate system for processing), additional input auxiliary textures and an output texture.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output;

/// Program factory used when creating the program from the given vertex and fragment sources.
/// Subclasses can override this factory to modify program's creation. The default factory is \c
/// LTBasicProgramFactory.
+ (id<LTProgramFactory>)programFactory;

/// Size of the input texture or the source texture, if there are auxiliary textures available.
@property (readonly, nonatomic) CGSize inputSize;

/// Size of the output texture.
@property (readonly, nonatomic) CGSize outputSize;

/// Output texture of the processor.
@property (readonly, nonatomic) LTTexture *outputTexture;

/// Input texture of the processor.
@property (readonly, nonatomic) LTTexture *inputTexture;

@end
