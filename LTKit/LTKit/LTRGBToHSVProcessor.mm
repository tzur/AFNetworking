// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTRGBToHSVProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTRGBToHSVFsh.h"

@implementation LTRGBToHSVProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [super initWithProgram:[self createProgram] input:input andOutput:output];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                  fragmentSource:[LTRGBToHSVFsh source]];
}

@end
