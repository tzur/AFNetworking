// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelConstructProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTLaplacianLevelConstructFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTLaplacianLevelConstructProcessor

- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseLevel
                      higherGaussianLevel:(LTTexture *)higherLevel
                            outputTexture:(LTTexture *)outputTexture {
  LTParameterAssert(baseLevel.size == outputTexture.size,
                    @"Output texture and base gaussin level must be of the same size");
  LTParameterAssert(outputTexture.dataType == LTGLPixelDataTypeFloat,
                    @"Output texture should be of floating precision");
  LTParameterAssert(higherLevel.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"Higher gaussian level min interpolation method must be Nearest Neighbour");
  LTParameterAssert(higherLevel.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"Higher gaussian level mag interpolation method must be Nearest Neighbour");

  NSDictionary *auxiliaryTextures = @{[LTLaplacianLevelConstructFsh higherLevel]: higherLevel};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTLaplacianLevelConstructFsh source]
                           sourceTexture:baseLevel
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:outputTexture]) {
    self[[LTLaplacianLevelConstructFsh inSituProcessing]] = @(baseLevel == outputTexture);
    self[[LTLaplacianLevelConstructFsh texelStep]] =
        $(LTVector2(1.0 / baseLevel.size.width, 1.0 / baseLevel.size.height));
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
