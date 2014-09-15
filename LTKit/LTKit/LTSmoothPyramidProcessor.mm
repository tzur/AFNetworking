// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSmoothPyramidProcessor.h"

#import "LTCGExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTPyramidProcessorVsh.h"
#import "LTShaderStorage+LTSmoothPyramidFsh.h"
#import "LTTexture+Factory.h"

#import "LTShaderStorage+LTPassthroughShaderVsh.h"

@implementation LTSmoothPyramidProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  if (self = [super initWithVertexSource:[LTPyramidProcessorVsh source]
                          fragmentSource:[LTSmoothPyramidFsh source]
                           sourceTexture:input outputs:outputs]) {
    self[[LTSmoothPyramidFsh texelStep]] = $(LTVector2(1.0 / input.size.width,
                                                       1.0 / input.size.height));
  }
  return self;
}

@end
