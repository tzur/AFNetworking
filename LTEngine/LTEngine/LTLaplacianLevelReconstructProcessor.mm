// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelReconstructProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTLaplacianLevelReconstructFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTLaplacianLevelReconstructProcessor

- (instancetype) initWithBaseLaplacianLevel:(LTTexture *)baseLaplacianLevel
                        higherGaussianLevel:(LTTexture *)higherGaussianLevel
                              outputTexture:(LTTexture *)outputTexture {
  return [self initWithBaseLaplacianLevel:baseLaplacianLevel baseLaplacianLevelBoost:1.0
                      higherGaussianLevel:higherGaussianLevel outputTexture:outputTexture];
}

- (instancetype) initWithBaseLaplacianLevel:(LTTexture *)baseLaplacianLevel
                    baseLaplacianLevelBoost:(CGFloat)baseLevelBoost
                        higherGaussianLevel:(LTTexture *)higherGaussianLevel
                              outputTexture:(LTTexture *)outputTexture {
  LTParameterAssert(baseLaplacianLevel.size == outputTexture.size,
                    @"output texture should be the same size as base Laplacian level");
  LTParameterAssert(baseLaplacianLevel.dataType == LTGLPixelDataTypeFloat,
                    @"base Laplacian level should be of floating precision");
  LTParameterAssert(higherGaussianLevel.minFilterInterpolation == LTTextureInterpolationNearest,
                    @"Higher gaussian level min interpolation method must be Nearest Neighbour");
  LTParameterAssert(higherGaussianLevel.magFilterInterpolation == LTTextureInterpolationNearest,
                    @"Higher gaussian level mag interpolation method must be Nearest Neighbour");

  NSDictionary *auxiliaryTextures =
      @{[LTLaplacianLevelReconstructFsh higherLevel]: higherGaussianLevel};

  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTLaplacianLevelReconstructFsh source]
                           sourceTexture:baseLaplacianLevel
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:outputTexture]) {
    self[[LTLaplacianLevelReconstructFsh inSituProcessing]] =
        @(baseLaplacianLevel == outputTexture);
    self[[LTLaplacianLevelReconstructFsh boostingFactor]] = @(baseLevelBoost);
    self[[LTLaplacianLevelReconstructFsh texelStep]] =
        $(LTVector2(1.0 / baseLaplacianLevel.size.width, 1.0 / baseLaplacianLevel.size.height));
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
