// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTHatPyramidProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTHatPyramidDownFsh.h"
#import "LTShaderStorage+LTHatPyramidUpFsh.h"
#import "LTShaderStorage+LTPyramidProcessorVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTHatPyramidProcessor ()

/// Name of the uniform holding the texel step size.
@property (readonly, nonatomic) NSString *texelStepUniformName;

/// YES iff the processor is set to downsample between levels of the pyramid.
@property (readonly, nonatomic) BOOL pyramidDownsampleProcessing;

@end

@implementation LTHatPyramidProcessor

- (instancetype)initWithInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs {
  _pyramidDownsampleProcessing = outputs.firstObject.size.width < input.size.width;

  [self verifyInput:input outputs:outputs];

  NSString *fragmentShaderSource;
  if (self.pyramidDownsampleProcessing) {
    _texelStepUniformName = [LTHatPyramidDownFsh texelStep];
    fragmentShaderSource = [LTHatPyramidDownFsh source];
  } else {
    _texelStepUniformName = [LTHatPyramidUpFsh texelStep];
    fragmentShaderSource = [LTHatPyramidUpFsh source];
  }
  return (self = [super initWithVertexSource:[LTPyramidProcessorVsh source]
                              fragmentSource:fragmentShaderSource
                               sourceTexture:input outputs:outputs]);
}

- (instancetype)initWithInput:(LTTexture *)input {
  return [self initWithInput:input outputs:[LTPyramidProcessor levelsForInput:input]];
}

- (void)verifyInput:(LTTexture *)input outputs:(NSArray<LTTexture *> *)outputs {
  LTParameterAssert(input.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"input texture min interpolation method must be Nearest Neighbour");
  LTParameterAssert(input.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"input texture mag interpolation method must be Nearest Neighbour");
  for (LTTexture *texture in outputs) {
    LTParameterAssert(texture.minFilterInterpolation == LTTextureInterpolationNearest,
                      @"output texture min interpolation method must be Nearest Neighbour");
    LTParameterAssert(texture.magFilterInterpolation == LTTextureInterpolationNearest,
                      @"output texture mag interpolation method must be Nearest Neighbour");
  }

  LTParameterAssert(outputs.count > 0, @"Output array cannot be empty");

  CGSize currentSize = input.size;
  if (self.pyramidDownsampleProcessing) {
    for (LTTexture *texture in outputs) {
      LTParameterAssert(texture.size.width < currentSize.width &&
                        texture.size.height < currentSize.height,
                        @"output textures for downsampling should be strongly monotonic in size");
      currentSize = texture.size;
    }
  } else {
    for (LTTexture *texture in outputs) {
      LTParameterAssert(texture.size.width > currentSize.width &&
                        texture.size.height > currentSize.height,
                        @"output textures for upsampling should be strongly monotonic in size");
      currentSize = texture.size;
    }
  }
}

- (void)iterationStarted:(NSUInteger)iteration {
  [super iterationStarted:iteration];

  if (self.pyramidDownsampleProcessing) {
    LTTexture *inputTexture;
    if (iteration == 0) {
      inputTexture = self.inputTexture;
    } else {
      inputTexture = self.outputTextures[iteration - 1];
    }
    self[self.texelStepUniformName] = $(LTVector2(1.0 / inputTexture.size.width,
                                                  1.0 / inputTexture.size.height));
  } else {
    LTTexture *outputTexture = self.outputTextures[iteration];
    self[self.texelStepUniformName] = $(LTVector2(1.0 / outputTexture.size.width,
                                                  1.0 / outputTexture.size.height));
  }
}

@end

NS_ASSUME_NONNULL_END
