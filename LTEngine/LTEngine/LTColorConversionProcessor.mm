// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorConversionProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTColorConversionProcessorFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTColorConversionProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [super initWithVertexSource:[LTPassthroughShaderVsh source]
                      fragmentSource:[LTColorConversionProcessorFsh source]
                               input:input andOutput:output];
}

- (void)setMode:(LTColorConversionMode)mode {
  _mode = mode;
  self[[LTColorConversionProcessorFsh mode]] = @(mode);
}

@end
