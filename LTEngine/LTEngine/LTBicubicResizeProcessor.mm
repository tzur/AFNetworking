// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBicubicResizeProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTBicubicResizeFsh.h"
#import "LTTexture.h"

@implementation LTBicubicResizeProcessor

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTBicubicResizeFsh source]
                                   input:input andOutput:output]) {
    self[[LTBicubicResizeFsh texelStep]] =
        $(LTVector2(1.0 / input.size.width, 1.0 / input.size.height));
  }
  return self;
}

@end
