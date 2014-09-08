// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTPyramidProcessor.h"

#import "LTCGExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTPyramidProcessorVsh.h"
#import "LTShaderStorage+LTPassthroughShaderFsh.h"
#import "LTTexture+Factory.h"

@implementation LTPyramidProcessor

+ (NSArray *)levelsForInput:(LTTexture *)input {
  NSUInteger levelCount = std::floor(std::log2(std::min(input.size))) - 1;

  NSMutableArray *levels = [NSMutableArray array];
  for (NSUInteger i = 0; i < levelCount; ++i) {
    LTTexture *texture = [LTTexture textureWithSize:std::ceil(input.size / std::pow(2, i + 1))
                                          precision:input.precision
                                             format:input.format
                                     allocateMemory:YES];
    [levels addObject:texture];
  }

  return levels;
}

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  if (self = [super initWithVertexSource:[LTPyramidProcessorVsh source]
                          fragmentSource:[LTPassthroughShaderFsh source]
                           sourceTexture:input outputs:outputs]) {
    NSMutableArray *iterationsPerOutput = [NSMutableArray array];
    for (NSUInteger i = 0; i < outputs.count; ++i) {
      [iterationsPerOutput addObject:@(i + 1)];
    }
    self.iterationsPerOutput = iterationsPerOutput;
  }
  return self;
}

- (void)iterationStarted:(NSUInteger)iteration {
  CGSize inputSize;
  if (iteration == 0) {
    inputSize = self.inputTexture.size;
  } else {
    inputSize = [self.outputTextures[iteration - 1] size];
  }

  self[[LTPyramidProcessorVsh texelOffset]] = $(LTVector2(CGSizeMakeUniform(-1) / (inputSize * 2)));
  self[[LTPyramidProcessorVsh texelScaling]] =
      $(LTVector2([self.outputTextures[iteration] size] * 2 / inputSize));
}

@end
