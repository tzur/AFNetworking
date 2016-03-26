// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotBaseImageProcessor.h"

@interface LTOneShotImageProcessor : LTOneShotBaseImageProcessor

/// Initializes with vertex and fragment shaders sources, a single input texture and a single output
/// texture.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                               input:(LTTexture *)input andOutput:(LTTexture *)output;

/// Designater initializer: Initializes with vertex and fragment shaders sources, a source texture
/// (which defines the coordinate system for processing), additional input auxiliary textures and an
/// output texture.
- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output;

@end
