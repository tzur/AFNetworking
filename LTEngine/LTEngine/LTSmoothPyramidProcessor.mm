// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTSmoothPyramidProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTPyramidProcessorVsh.h"
#import "LTShaderStorage+LTSmoothPyramidFsh.h"
#import "LTTexture+Factory.h"

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

- (void)iterationStarted:(NSUInteger)iteration {
  [super iterationStarted:iteration];

  LTTexture *inputTexture;
  LTTexture *outputTexture = self.outputTextures[iteration];
  if (iteration == 0) {
    inputTexture = self.inputTexture;
  } else {
    inputTexture = self.outputTextures[iteration - 1];
  }

  // If pyramid iterations are of the \c pyrUp operation (downsampling) then the texelstep needs to
  // be updated in every iteration. Otherwise for any level after the first one the same texel will
  // be read in each of the taps.
  if (outputTexture.size.width < inputTexture.size.width || self.updateTexelStepInUpsample) {
    self[[LTSmoothPyramidFsh texelStep]] = $(LTVector2(1.0 / inputTexture.size.width,
                                                       1.0 / inputTexture.size.height));
  }
}

@end
