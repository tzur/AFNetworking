// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTRGBToHSVProcessor.h"

#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTRGBToHSVFsh.h"

@implementation LTRGBToHSVProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [super initWithVertexSource:[LTPassthroughShaderVsh source]
                      fragmentSource:[LTRGBToHSVFsh source] input:input andOutput:output];
}

@end
