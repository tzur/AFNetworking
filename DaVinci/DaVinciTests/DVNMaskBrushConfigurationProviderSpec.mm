// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNMaskBrushConfigurationProvider.h"

#import <LTEngine/LTFloatSetSampler.h>
#import <LTEngine/LTPeriodicFloatSet.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNBrushTipsProvider.h"
#import "DVNCanonicalTexCoordProvider.h"
#import "DVNMaskBrushParametersProvider.h"
#import "DVNPatternSamplingStageModel.h"
#import "DVNPipelineConfiguration.h"
#import "DVNQuadAttributeProvider.h"
#import "DVNRenderStageConfiguration.h"
#import "DVNSquareProvider.h"
#import "DVNTextureMappingStageConfiguration.h"
#import "LTShaderStorage+DVNMaskBrushFsh.h"
#import "LTShaderStorage+DVNMaskBrushVsh.h"

@interface DVNFakeMaskBrushParametersProvider : NSObject <DVNMaskBrushParametersProvider>
@property (readwrite, nonatomic) CGFloat spacing;
@property (readwrite, nonatomic) CGFloat hardness;
@property (readwrite, nonatomic) CGFloat diameter;
@property (readwrite, nonatomic) CGFloat edgeAvoidance;
@property (readwrite, nonatomic) CGFloat flow;
@property (readwrite, nonatomic) DVNMaskBrushMode mode;
@property (readwrite, nonatomic) DVNMaskBrushChannel channel;
@property (readwrite, nonatomic) LTTexture *edgeAvoidanceGuideTexture;
@end

@implementation DVNFakeMaskBrushParametersProvider
@synthesize spacing = _spacing;
@synthesize hardness = _hardness;
@synthesize diameter = _diameter;
@synthesize edgeAvoidance = _edgeAvoidance;
@synthesize flow = _flow;
@synthesize mode = _mode;
@synthesize channel = _channel;
@synthesize edgeAvoidanceGuideTexture = _edgeAvoidanceGuideTexture;
@end

SpecBegin(DVNMaskBrushConfigurationProvider)

__block DVNFakeMaskBrushParametersProvider *parametersProvider;
__block DVNBrushTipsProvider *brushTipsProvider;
__block DVNMaskBrushConfigurationProvider *provider;
__block LTTexture *smoothTipTexture;
__block LTTexture *hardTipTexture;

static const CGFloat kAdditiveChangeFactor = 0.1;

beforeEach(^{
  parametersProvider = [[DVNFakeMaskBrushParametersProvider alloc] init];
  parametersProvider.spacing = 0.1;
  parametersProvider.hardness = 0.5;
  parametersProvider.diameter = 5;
  parametersProvider.edgeAvoidance = 0.5;
  parametersProvider.flow = 0.75;
  parametersProvider.mode = DVNMaskBrushModeAdd;
  parametersProvider.channel = DVNMaskBrushChannelR;
  parametersProvider.edgeAvoidanceGuideTexture = [LTTexture textureWithImage:cv::Mat4b(10, 20)];
  
  smoothTipTexture = OCMClassMock([LTTexture class]);
  hardTipTexture = OCMClassMock([LTTexture class]);
  brushTipsProvider = OCMClassMock([DVNBrushTipsProvider class]);
  OCMStub([brushTipsProvider
           roundTipWithDimension:kMaskBrushDimension
           hardness:parametersProvider.hardness]).andReturn(smoothTipTexture);
  OCMStub([brushTipsProvider
           roundTipWithDimension:kMaskBrushDimension
           hardness:parametersProvider.hardness + kAdditiveChangeFactor]).andReturn(hardTipTexture);
  
  provider = [[DVNMaskBrushConfigurationProvider alloc]
              initWithParametersProvider:parametersProvider brushTipsProvider:brushTipsProvider];
});

afterEach(^{
  parametersProvider = nil;
  provider = nil;
  smoothTipTexture = nil;
  hardTipTexture = nil;
  brushTipsProvider = nil;
});

context(@"initialization", ^{
  it(@"should initialized correctly", ^{
    expect(provider).toNot.beNil();
  });
});

context(@"provider", ^{
  __block DVNPipelineConfiguration *configuration;
  
  beforeEach(^{
    configuration = [provider configuration];
  });
  
  afterEach(^{
    configuration = nil;
  });
  
  it(@"should return valid DVNPipelineConfiguration object", ^{
    expect(configuration).toNot.beNil();
  });

  context(@"sampling stage configuration", ^{
    it(@"should return a configuration with sampler of correct class", ^{
      expect(configuration.samplingStageConfiguration).to.beKindOf([LTFloatSetSamplerModel class]);
    });
    
    it(@"should have a sampler with periodic float set", ^{
      LTFloatSetSamplerModel *samplerModel = configuration.samplingStageConfiguration;
      expect(samplerModel.floatSet).to.beKindOf([LTPeriodicFloatSet class]);
    });
    
    it(@"should have a sampler with correct periodic float set", ^{
      LTFloatSetSamplerModel *samplerModel = configuration.samplingStageConfiguration;
      LTPeriodicFloatSet *floatSet = samplerModel.floatSet;
      expect(floatSet.pivotValue).to.equal(0);
      expect(floatSet.numberOfValuesPerSequence).to.equal(1);
      expect(floatSet.valueDistance).to.equal(parametersProvider.spacing);
      expect(floatSet.sequenceDistance).to.equal(parametersProvider.spacing);
    });
    
    it(@"should have a sampler with correct interval", ^{
      LTFloatSetSamplerModel *samplerModel = configuration.samplingStageConfiguration;
      lt::Interval<CGFloat> interval = samplerModel.interval;
      expect(interval.min()).to.equal(0);
      expect(interval.max()).to.equal(CGFLOAT_MAX);
      expect(interval.maxEndpointIncluded())
          .to.equal(lt::Interval<CGFloat>::EndpointInclusion::Closed);
    });
  });

  context(@"geometry stage configuration", ^{
    it(@"should return a configuration with correct DVNGeometryProviderModel", ^{
      expect(configuration.geometryStageConfiguration).to.beKindOf([DVNSquareProviderModel class]);
      
      DVNSquareProviderModel *model =
          (DVNSquareProviderModel *)configuration.geometryStageConfiguration;
      expect(model.edgeLength).to.equal(parametersProvider.diameter);
    });
    
    it(@"should return correct configuration after diameter parameter has changed", ^{
      parametersProvider.diameter += kAdditiveChangeFactor;
      DVNSquareProviderModel *model =
          (DVNSquareProviderModel *)[provider configuration].geometryStageConfiguration;
      expect(model.edgeLength).to.equal(parametersProvider.diameter);
    });
  });
  
  context(@"texture mapping stage configuration", ^{
    it(@"should return a configuration with correct DVNTextureMappingStageConfiguration", ^{
      DVNTextureMappingStageConfiguration *textureMappingStageConfiguration =
      configuration.textureStageConfiguration;
      expect(textureMappingStageConfiguration.texture).to.equal(smoothTipTexture);
      expect(textureMappingStageConfiguration.model)
          .to.beKindOf([DVNCanonicalTexCoordProviderModel class]);
    });
    
    it(@"should return correct configuration after hardness parameter has changed", ^{
      parametersProvider.hardness += kAdditiveChangeFactor;
      expect([provider configuration].textureStageConfiguration.texture).to.equal(hardTipTexture);
    });
  });
  
  it(@"should return a configuration with correct DVNAttributeStageConfiguration", ^{
    DVNAttributeStageConfiguration *attributeStageConfiguration =
        configuration.attributeStageConfiguration;
    expect(attributeStageConfiguration.models)
        .to.equal(@[[[DVNQuadAttributeProviderModel alloc] init]]);
  });
  
  context(@"rendering stage configuration", ^{
    it(@"should return a configuration with correct DVNRenderStageConfiguration", ^{
      DVNRenderStageConfiguration *renderStageConfiguration =
          configuration.renderStageConfiguration;
      NSDictionary<NSString *, LTTexture *> *expectedAuxiliaryTextures = @{
        [DVNMaskBrushFsh edgeAvoidanceGuideTexture]: parametersProvider.edgeAvoidanceGuideTexture
      };
      NSDictionary<NSString *, NSValue *> *expectedUniforms = @{
        [DVNMaskBrushFsh channel]: @(parametersProvider.channel),
        [DVNMaskBrushFsh mode]: @(parametersProvider.mode),
        [DVNMaskBrushFsh flow]: @(parametersProvider.flow),
        [DVNMaskBrushFsh edgeAvoidance]: @(parametersProvider.edgeAvoidance)
      };
      expect(renderStageConfiguration.vertexSource).to.equal([DVNMaskBrushVsh source]);
      expect(renderStageConfiguration.fragmentSource).to.equal([DVNMaskBrushFsh source]);
      expect(renderStageConfiguration.auxiliaryTextures).to.equal(expectedAuxiliaryTextures);
      expect(renderStageConfiguration.uniforms).to.equal(expectedUniforms);
    });
    
    it(@"should return correct configuration after parameters have changed", ^{
      parametersProvider.channel = DVNMaskBrushChannelG;
      parametersProvider.mode = DVNMaskBrushModeSubtract;
      parametersProvider.flow += kAdditiveChangeFactor;
      parametersProvider.edgeAvoidance += kAdditiveChangeFactor;
      parametersProvider.edgeAvoidanceGuideTexture = OCMClassMock([LTTexture class]);
      DVNRenderStageConfiguration *renderStageConfiguration =
          [provider configuration].renderStageConfiguration;
      NSDictionary<NSString *, LTTexture *> *expectedAuxiliaryTextures = @{
        [DVNMaskBrushFsh edgeAvoidanceGuideTexture]: parametersProvider.edgeAvoidanceGuideTexture
      };
      NSDictionary<NSString *, NSValue *> *expectedUniforms = @{
        [DVNMaskBrushFsh channel]: @(parametersProvider.channel),
        [DVNMaskBrushFsh mode]: @(parametersProvider.mode),
        [DVNMaskBrushFsh flow]: @(parametersProvider.flow),
        [DVNMaskBrushFsh edgeAvoidance]: @(parametersProvider.edgeAvoidance)
      };
      expect(renderStageConfiguration.vertexSource).to.equal([DVNMaskBrushVsh source]);
      expect(renderStageConfiguration.fragmentSource).to.equal([DVNMaskBrushFsh source]);
      expect(renderStageConfiguration.auxiliaryTextures).to.equal(expectedAuxiliaryTextures);
      expect(renderStageConfiguration.uniforms).to.equal(expectedUniforms);
    });
  });
});

SpecEnd
