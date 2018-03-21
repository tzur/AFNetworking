// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushRenderConfigurationProviderV1.h"

#import <LTEngine/LTFloatSetSampler.h>
#import <LTEngine/LTPeriodicFloatSet.h>
#import <LTEngine/LTTexture.h>
#import <LTEngine/LTTextureAtlas.h>
#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+NSSet.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNBlendMode.h"
#import "DVNBrushModelV1.h"
#import "DVNBrushRenderConfigurationProvider.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"
#import "DVNCanonicalTexCoordProvider.h"
#import "DVNJitteredColorAttributeProviderModel.h"
#import "DVNPipelineConfiguration.h"
#import "DVNQuadCenterAttributeProvider.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNScatteredGeometryProviderModel.h"
#import "DVNSquareProvider.h"
#import "DVNTextureMappingStageConfiguration+TextureAtlas.h"
#import "LTShaderStorage+DVNBrushV1Fsh.h"
#import "LTShaderStorage+DVNBrushV1Vsh.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DVNBrushV1FshSourceTextureSampleMode) {
  DVNBrushV1FshSourceTextureSampleModeSubimage,
  DVNBrushV1FshSourceTextureSampleModeFixed,
  DVNBrushV1FshSourceTextureSampleModeQuadCenter
};

@implementation DVNBrushRenderConfigurationProviderV1

#pragma mark -
#pragma mark Initialization - Auxiliary Methods
#pragma mark -

- (id<LTContinuousSamplerModel>)samplingStageConfigurationFromModel:(DVNBrushModelV1 *)model
                                                   conversionFactor:(CGFloat)conversionFactor {
  CGFloat scaleInSplineCoordinates = conversionFactor * model.scale;
  CGFloat sequenceDistance = model.sequenceDistance * scaleInSplineCoordinates;
  LTPeriodicFloatSet *floatSet =
      [[LTPeriodicFloatSet alloc] initWithPivotValue:0
                           numberOfValuesPerSequence:model.numberOfSamplesPerSequence
                                       valueDistance:model.spacing * scaleInSplineCoordinates
                                    sequenceDistance:sequenceDistance];
  lt::Interval<CGFloat> interval = lt::Interval<CGFloat>::nonNegativeNumbers();
  return [[LTFloatSetSamplerModel alloc] initWithFloatSet:floatSet interval:interval];
}

- (id<DVNGeometryProviderModel>)geometryStageConfigurationFromModel:(DVNBrushModelV1 *)model
                                                   conversionFactor:(CGFloat)conversionFactor {
  CGFloat scaleInSplineCoordinates = conversionFactor * model.scale;
  DVNSquareProviderModel *providerModel = [[DVNSquareProviderModel alloc] initWithEdgeLength:1];

  lt::Interval<CGFloat> distance({
    *model.distanceJitterFactorRange.min() * scaleInSplineCoordinates,
    *model.distanceJitterFactorRange.max() * scaleInSplineCoordinates
  });
  lt::Interval<CGFloat> angle = model.angleRange;
  lt::Interval<CGFloat> scaleJitter({
    *model.scaleJitterRange.min() * scaleInSplineCoordinates,
    *model.scaleJitterRange.max() * scaleInSplineCoordinates
  });
  lt::Interval<NSUInteger> count = model.countRange;
  return [[DVNScatteredGeometryProviderModel alloc]
          initWithGeometryProviderModel:providerModel randomState:[self randomStateFromModel:model]
          count:count distance:distance angle:angle scale:scaleJitter
          lengthOfStartTapering:model.taperingLengths.x lengthOfEndTapering:model.taperingLengths.y
          startTaperingFactor:model.taperingFactors.x endTaperingFactor:model.taperingFactors.y
          minimumTaperingScaleFactor:model.minimumTaperingScaleFactor];
}

- (LTRandomState *)randomStateFromModel:(DVNBrushModelV1 *)model {
  return model.randomInitialSeed ? [[LTRandomState alloc] init] :
      [[LTRandom alloc] initWithSeed:model.initialSeed].engineState;
}

- (DVNAttributeStageConfiguration *)attributeStageConfigurationFromModel:(DVNBrushModelV1 *)model {
  LTRandomState *randomState = [self randomStateFromModel:model];
  return [[DVNAttributeStageConfiguration alloc] initWithAttributeProviderModels:@[
    [[DVNQuadCenterAttributeProviderModel alloc] init],
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:model.color
                                                     brightnessJitter:model.brightnessJitter
                                                            hueJitter:model.hueJitter
                                                     saturationJitter:model.saturationJitter
                                                          randomState:randomState]
  ]];
}

#pragma mark -
#pragma mark DVNBrushRenderConfigurationProvider
#pragma mark -

- (DVNPipelineConfiguration *)configurationForModel:(DVNBrushRenderModel *)model
    withTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  LTParameterAssert([model.brushModel isKindOfClass:[DVNBrushModelV1 class]], @"Invalid object: %@",
                    model.brushModel);
  DVNBrushModelV1 *brushModel = (DVNBrushModelV1 *)model.brushModel;

  LTParameterAssert(textureMapping[@keypath(brushModel, sourceImageURL)],
                    @"Texture mapping (%@) must provide texture for source image", textureMapping);
  LTParameterAssert(textureMapping[@keypath(brushModel, maskImageURL)],
                    @"Texture mapping (%@) must provide texture for mask image", textureMapping);
  LTParameterAssert([textureMapping.allKeys.lt_set
                     isSubsetOfSet:[[brushModel class] imageURLPropertyKeys].lt_set],
                    @"Keys of texture mapping %@ must be subset of image URL property keys %@ of "
                    "brush model %@", textureMapping, [[brushModel class] imageURLPropertyKeys],
                    brushModel);
  LTParameterAssert([brushModel.edgeAvoidanceGuideImageURL.absoluteString isEqualToString:@""] ||
                    textureMapping[@keypath(brushModel, edgeAvoidanceGuideImageURL)],
                    @"Edge avoidance guide texture must be provided if corresponding URL (%@) is "
                    "not empty", brushModel.edgeAvoidanceGuideImageURL);

  id<LTContinuousSamplerModel> samplingStageConfiguration =
      [self samplingStageConfigurationFromModel:brushModel conversionFactor:model.conversionFactor];
  id<DVNGeometryProviderModel> geometryStageConfiguration =
      [self geometryStageConfigurationFromModel:brushModel
                               conversionFactor:model.conversionFactor];
  DVNTextureMappingStageConfiguration *textureMappingStageConfiguration =
      [self textureMappingStageConfigurationFromModel:brushModel textureMapping:textureMapping];

  return [[DVNPipelineConfiguration alloc]
          initWithSamplingStageConfiguration:samplingStageConfiguration
          geometryStageConfiguration:geometryStageConfiguration
          textureMappingStageConfiguration:textureMappingStageConfiguration
          attributeStageConfiguration:[self attributeStageConfigurationFromModel:brushModel]
          renderStageConfiguration:[self renderStageConfigurationFromRenderModel:model
                                                                  textureMapping:textureMapping]];
}

#pragma mark -
#pragma mark DVNBrushRenderConfigurationProvider - Auxiliary Methods
#pragma mark -

- (DVNTextureMappingStageConfiguration *)
    textureMappingStageConfigurationFromModel:(DVNBrushModelV1 *)model
    textureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  LTTexture *texture = textureMapping[@keypath(model, sourceImageURL)];

  LTVector2 gridSize = model.brushTipImageGridSize;

  if (gridSize != LTVector2::ones()) {
    lt::unordered_map<NSString *, CGRect> areas;

    CGRect rect = CGRectFromSize(texture.size);
    CGRects textureRegions = CGRectRegularGrid(rect, gridSize.x, gridSize.y);

    for (CGRects::size_type i = 0; i < textureRegions.size(); ++i) {
      CGRect intersectedRect = CGRectIntersection(textureRegions[i], rect);
      areas.insert({[@(i) stringValue], intersectedRect});
    }
    LTTextureAtlas *atlas = [[LTTextureAtlas alloc] initWithAtlasTexture:texture imageAreas:areas];
    return [DVNTextureMappingStageConfiguration
            configurationFromTextureAtlas:atlas randomState:[self randomStateFromModel:model]];
  } else {
    DVNCanonicalTexCoordProviderModel *model = [[DVNCanonicalTexCoordProviderModel alloc] init];
    return [[DVNTextureMappingStageConfiguration alloc] initWithTexCoordProviderModel:model
                                                                              texture:texture];
  }
}

- (DVNRenderStageConfiguration *)
    renderStageConfigurationFromRenderModel:(DVNBrushRenderModel *)model
    textureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping {
  DVNBrushModelV1 *brushModel = (DVNBrushModelV1 *)model.brushModel;

  LTTexture *sourceTexture = textureMapping[@keypath(brushModel, sourceImageURL)];
  LTTexture *maskTexture = textureMapping[@keypath(brushModel, maskImageURL)];

  LTTexture * _Nullable edgeAvoidanceGuideTexture =
      textureMapping[@keypath(brushModel, edgeAvoidanceGuideImageURL)];

  DVNBrushV1FshSourceTextureSampleMode sourceTextureSampleMode;
  BOOL sampleUniformColorFromColorTexture = NO;

  switch (brushModel.sourceSamplingMode.value) {
    case DVNSourceSamplingModeSubimage:
      sourceTextureSampleMode = DVNBrushV1FshSourceTextureSampleModeSubimage;
      break;
    case DVNSourceSamplingModeFixed:
      sourceTextureSampleMode = DVNBrushV1FshSourceTextureSampleModeFixed;
      break;
    case DVNSourceSamplingModeQuadCenter:
      sampleUniformColorFromColorTexture = YES;
      sourceTextureSampleMode = DVNBrushV1FshSourceTextureSampleModeQuadCenter;
      break;
  }

  DVNBrushRenderTargetInformation *info = model.renderTargetInfo;

  NSDictionary<NSString *, NSValue *> *uniforms = @{
    [DVNBrushV1Fsh flow]: @(pow(brushModel.flow, brushModel.flowExponent)),
    [DVNBrushV1Fsh sourceTextureIsNonPremultiplied]: @(brushModel.sourceImageIsNonPremultiplied),
    [DVNBrushV1Fsh sourceTextureSampleMode]: @(sourceTextureSampleMode),
    [DVNBrushV1Fsh sourceTextureCoordTransform]: $(GLKMatrix4Identity),
    [DVNBrushV1Fsh blendMode]: @(brushModel.blendMode.value),
    [DVNBrushV1Fsh edgeAvoidance]: @(edgeAvoidanceGuideTexture ? brushModel.edgeAvoidance : 0),
    [DVNBrushV1Vsh modelview]:
        $([self modelviewMatrixWithRenderTargetLocation:info.renderTargetLocation]),
    [DVNBrushV1Fsh renderTargetHasSingleChannel]: @(info.renderTargetHasSingleChannel),
    [DVNBrushV1Fsh renderTargetIsNonPremultiplied]: @(info.renderTargetIsNonPremultiplied),
    [DVNBrushV1Vsh edgeAvoidanceSamplingOffset]:
        $(LTVector2(model.conversionFactor * brushModel.edgeAvoidanceSamplingOffset)),
    [DVNBrushV1Vsh colorTextureIsNonPremultiplied]: @(brushModel.sourceImageIsNonPremultiplied),
    [DVNBrushV1Vsh sampleUniformColorFromColorTexture]: @(sampleUniformColorFromColorTexture),
  };

  auto auxiliaryTextures = [@{[DVNBrushV1Fsh maskTexture]: maskTexture} mutableCopy];

  auxiliaryTextures[[DVNBrushV1Vsh colorTexture]] =
      sampleUniformColorFromColorTexture ? sourceTexture : nil;
  auxiliaryTextures[[DVNBrushV1Fsh edgeAvoidanceGuideTexture]] =
      brushModel.edgeAvoidance ? edgeAvoidanceGuideTexture : nil;

  return [[DVNRenderStageConfiguration alloc] initWithVertexSource:[DVNBrushV1Vsh source]
                                                    fragmentSource:[DVNBrushV1Fsh source]
                                                 auxiliaryTextures:auxiliaryTextures
                                                          uniforms:uniforms];
}

- (GLKMatrix4)modelviewMatrixWithRenderTargetLocation:(lt::Quad)renderTargetLocation {
  GLKMatrix3 transform = GLKMatrix3Invert(GLKMatrix3Transpose(renderTargetLocation.transform()),
                                          NULL);
  return GLKMatrix4Make(transform.m00, transform.m01, 0, transform.m02,
                        transform.m10, transform.m11, 0, transform.m12,
                        0, 0, 1, 0,
                        transform.m20, transform.m21, 0, transform.m22);
}

@end

NS_ASSUME_NONNULL_END
