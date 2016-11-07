// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTColorConversionProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTColorConversionProcessorFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

@implementation LTColorConversionProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  return [self initWithInput:input auxiliaryInput:nil output:output];
}

- (instancetype)initWithInput:(LTTexture *)input auxiliaryInput:(LTTexture *)auxiliaryInput
                       output:(LTTexture *)output {
  NSDictionary *auxiliaryTextures = auxiliaryInput ?
      @{[LTColorConversionProcessorFsh auxiliaryTexture]: auxiliaryInput} : nil;
  return self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                             fragmentSource:[LTColorConversionProcessorFsh source]
                              sourceTexture:input
                          auxiliaryTextures:auxiliaryTextures
                                  andOutput:output];
}

- (void)setMode:(LTColorConversionMode)mode {
  _mode = mode;
  self[[LTColorConversionProcessorFsh mode]] = @(mode);
}

@end
