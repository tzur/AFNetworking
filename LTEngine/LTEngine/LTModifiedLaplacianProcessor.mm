// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTModifiedLaplacianProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTModifiedLaplacianFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTModifiedLaplacianProcessor

- (instancetype)initWithTexture:(LTTexture *)input output:(LTTexture *)output
                  pixelStepSize:(float)pixelStep {
  LTParameterAssert(output.pixelFormat.components == LTGLPixelComponentsR,
                    @"Exposure weight map Output must be single channel");
  LTParameterAssert(output.size  == input.size, @"Input and output size must be equal");
  LTParameterAssert(input.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"Input texture must use Nearest Neighbour min interpolation");
  LTParameterAssert(input.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"Input texture must use Nearest Neighbour mag interpolation");

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTModifiedLaplacianFsh source]
                                   input:input andOutput:output]) {
    self[[LTModifiedLaplacianFsh texelStep]] = $(LTVector2(pixelStep / input.size.width,
                                                           pixelStep / input.size.height));
  }
  return self;
}

- (instancetype)initWithTexture:(LTTexture *)input output:(LTTexture *)output {
  return [self initWithTexture:input output:output pixelStepSize:1.0];
}

@end

NS_ASSUME_NONNULL_END
