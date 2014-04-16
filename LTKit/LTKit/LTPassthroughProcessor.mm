// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPassthroughProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTPassthroughProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [super initWithProgram:[self createProgram] input:input andOutput:output];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTPassthroughShaderFsh source]];
}

@end
