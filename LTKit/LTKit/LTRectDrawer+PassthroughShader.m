// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRectDrawer+PassthroughShader.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTRectDrawer (PassthroughShader)

- (instancetype)initWithSourceTexture:(LTTexture *)texture {
  return [self initWithProgram:[[LTProgram alloc]
                                initWithVertexSource:[LTPassthroughShaderVsh source]
                                      fragmentSource:[LTPassthroughShaderFsh source]]
                 sourceTexture:texture];
}

@end
