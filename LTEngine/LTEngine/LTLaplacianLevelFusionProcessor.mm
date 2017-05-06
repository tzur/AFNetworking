// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Bibi.

#import "LTLaplacianLevelFusionProcessor.h"

#import "LTGPUImageProcessor+Protected.h"
#import "LTShaderStorage+LTLaplacianLevelFusionFsh.h"
#import "LTShaderStorage+LTLaplacianLevelFusionLastLevelFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTLaplacianLevelFusionProcessor

- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseGaussianLevel
                      higherGaussianLevel:(nullable LTTexture *)higherGaussianLevel
                          baseWeightLevel:(LTTexture *)baseLevelWeightMap
                         addToOutputLevel:(LTTexture *)output {
  [self verifyBaseGaussianLevel:baseGaussianLevel higherGaussianLevel:higherGaussianLevel
                baseWeightLevel:baseLevelWeightMap addToOutputLevel:output];

  NSDictionary *auxiliaryTextures;
  NSString *fragmentShaderSource;
  if (higherGaussianLevel) {
    auxiliaryTextures = @{[LTLaplacianLevelFusionFsh higherGaussianLevel]: higherGaussianLevel,
                          [LTLaplacianLevelFusionFsh weightMap]: baseLevelWeightMap};
    fragmentShaderSource = [LTLaplacianLevelFusionFsh source];
  } else {
    auxiliaryTextures = @{[LTLaplacianLevelFusionLastLevelFsh weightMap]: baseLevelWeightMap};
    fragmentShaderSource = [LTLaplacianLevelFusionLastLevelFsh source];
  }

  self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                      fragmentSource:fragmentShaderSource
                       sourceTexture:baseGaussianLevel
                   auxiliaryTextures:auxiliaryTextures
                           andOutput:output];

  if (higherGaussianLevel) {
    self[[LTLaplacianLevelFusionFsh texelStep]] =
        $(LTVector2(1.0 / baseGaussianLevel.size.width, 1.0 / baseGaussianLevel.size.height));
  }

  return self;
}

- (instancetype)initWithBaseGaussianLevel:(LTTexture *)baseGaussianLevel
                          baseWeightLevel:(LTTexture *)baseLevelWeightMap
                         addToOutputLevel:(LTTexture *)output {
  return [self initWithBaseGaussianLevel:baseGaussianLevel higherGaussianLevel:nil
                         baseWeightLevel:baseLevelWeightMap addToOutputLevel:output];
}

- (void)verifyBaseGaussianLevel:(LTTexture *)baseGaussianLevel
            higherGaussianLevel:(nullable LTTexture *)higherGaussianLevel
                baseWeightLevel:(LTTexture *)baseLevelWeightMap
               addToOutputLevel:(LTTexture *)output {
  LTParameterAssert(baseGaussianLevel.size == baseLevelWeightMap.size,
                    @"Weight map size must be the same as the base gaussian level size");
  LTParameterAssert(baseGaussianLevel.size == output.size,
                    @"output size must be the same as the base gaussian level size");
  LTParameterAssert([baseLevelWeightMap.pixelFormat isEqual:$(LTGLPixelFormatR16Float)],
                    @"Exposure weight map should be of type R16Float");
  LTParameterAssert(output.dataType == LTGLPixelDataType16Float,
                    @"Output Laplacian layer should be of data type Float");

  if (higherGaussianLevel) {
    LTParameterAssert(higherGaussianLevel.minFilterInterpolation == LTTextureInterpolationNearest,
                      @"Higher gaussian level min interpolation method must be Nearest Neighbour");
    LTParameterAssert(higherGaussianLevel.magFilterInterpolation == LTTextureInterpolationNearest,
                      @"Higher gaussian level mag interpolation method must be Nearest Neighbour");
  }
}

@end

NS_ASSUME_NONNULL_END
