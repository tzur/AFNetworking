// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "CAMExposureMapProcessor.h"

#import <LTEngine/LTShaderStorage+LTPassthroughShaderVsh.h>
#import <LTEngine/LTTexture.h>

#import "LTShaderStorage+CAMExposureMapFsh.h"

NS_ASSUME_NONNULL_BEGIN

@implementation CAMExposureMapProcessor

- (instancetype)initWithTexture:(LTTexture *)input output:(LTTexture *)output {
  LTParameterAssert([output.pixelFormat isEqual:$(LTGLPixelFormatR16Float)],
                    @"Exposure weight map output must be of type R16Float");
  LTParameterAssert(input.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"Input texture must use Nearest Neighbour min interpolation");
  LTParameterAssert(input.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"Input texture must use Nearest Neighbour mag interpolation");
  LTParameterAssert(output.size == input.size,
                    @"Output weight map must be of the same size as the input texture.");

  return [super initWithVertexSource:[LTPassthroughShaderVsh source]
                      fragmentSource:[CAMExposureMapFsh source]
                               input:input
                           andOutput:output];
}

@end

NS_ASSUME_NONNULL_END
