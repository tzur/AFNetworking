// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTOneShotImageProcessor.h"

#import "LTProgramFactory.h"
#import "LTRectDrawer.h"

/// Processes a single image input with a single processing iteration, and returns a single output,
/// using an \c LTRectDrawer for drawing the output.
@implementation LTOneShotImageProcessor

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                               input:(LTTexture *)input andOutput:(LTTexture *)output {
  return [self initWithVertexSource:vertexSource fragmentSource:fragmentSource
                      sourceTexture:input auxiliaryTextures:nil andOutput:output];
}

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                   auxiliaryTextures:(NSDictionary *)auxiliaryTextures
                           andOutput:(LTTexture *)output {
  LTProgram *program = [[[self class] programFactory] programWithVertexSource:vertexSource
                                                               fragmentSource:fragmentSource];
  LTRectDrawer *drawer = [[LTRectDrawer alloc] initWithProgram:program sourceTexture:sourceTexture];
  return [super initWithDrawer:drawer sourceTexture:sourceTexture
             auxiliaryTextures:auxiliaryTextures
                    andOutput:output];
}

@end
