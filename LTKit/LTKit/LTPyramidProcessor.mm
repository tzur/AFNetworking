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
  NSUInteger levelCount = MAX(1, std::floor(std::log2(std::min(input.size))) - 1);

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

- (instancetype)initWithVertexSource:(NSString *)vertexSource
                      fragmentSource:(NSString *)fragmentSource
                       sourceTexture:(LTTexture *)sourceTexture
                             outputs:(NSArray *)outputs {
  if (self = [super initWithVertexSource:vertexSource fragmentSource:fragmentSource
                           sourceTexture:sourceTexture outputs:outputs]) {
    NSMutableArray *iterationsPerOutput = [NSMutableArray array];
    for (NSUInteger i = 0; i < outputs.count; ++i) {
      [iterationsPerOutput addObject:@(i + 1)];
    }
    self.iterationsPerOutput = iterationsPerOutput;
  }
  return self;
}

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray *)outputs {
  return [self initWithVertexSource:[LTPyramidProcessorVsh source]
                     fragmentSource:[LTPassthroughShaderFsh source]
                      sourceTexture:input outputs:outputs];
}

- (void)iterationStarted:(NSUInteger)iteration {
  LTTexture *inputTexture;
  LTTexture *outputTexture = self.outputTextures[iteration];

  if (iteration == 0) {
    inputTexture = self.inputTexture;
  } else {
    inputTexture = self.outputTextures[iteration - 1];
  }

  CGSize inputSize = inputTexture.size;
  
  // If texture uses a nearest neigbour interpolation, texelOffset and texelScaling are set to
  // ensure (1:2:end) sampling pattern (in Matlab notation).
  // In case of bilinear interpolation texelOffset is set to zero and texelScaling to one. This will
  // result in default OpenGL behavior when writing from input to output texture of different sizes.
  LTTextureInterpolation inputInterpolation;
  if (outputTexture.size.width < inputSize.width && outputTexture.size.height < inputSize.height) {
    inputInterpolation = inputTexture.minFilterInterpolation;
  } else {
    inputInterpolation = inputTexture.magFilterInterpolation;
  }

  LTVector2 texelOffset;
  LTVector2 texelScaling;
  switch (inputInterpolation) {
    case LTTextureInterpolationNearest:
      if (outputTexture.size.width < inputTexture.size.width) {
        texelScaling = LTVector2([self.outputTextures[iteration] size] * 2 / inputSize);
      } else {
        texelScaling = LTVector2([self.outputTextures[iteration] size] / (inputSize * 2));
      }
      texelOffset = LTVector2(CGSizeMakeUniform(-1) / (inputSize * 2));
      break;
    default:
      texelScaling = LTVector2One;
      texelOffset = LTVector2Zero;
      break;
  }
  
  self[[LTPyramidProcessorVsh texelOffset]] = $(texelOffset);
  self[[LTPyramidProcessorVsh texelScaling]] = $(texelScaling);
}

@end
