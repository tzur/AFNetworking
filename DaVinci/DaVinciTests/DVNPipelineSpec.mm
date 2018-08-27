// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPipeline.h"

#import <LTEngine/LTFbo.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNPipelineConfiguration.h"
#import "DVNTestPipelineConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

SpecBegin(DVNPipeline)

static const lt::Interval<CGFloat> kInterval = lt::Interval<CGFloat>::zeroToOne();

__block DVNPipelineConfiguration *initialConfiguration;
__block DVNPipeline *pipeline;

beforeEach(^{
  initialConfiguration = DVNTestPipelineConfiguration();
  pipeline = [[DVNPipeline alloc] initWithConfiguration:initialConfiguration];
});

afterEach(^{
  pipeline = nil;
  initialConfiguration = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(pipeline).toNot.beNil();
  });

  it(@"should provide initial configuration as current configuration after initialization", ^{
    DVNPipelineConfiguration *configuration = pipeline.currentConfiguration;
    expect(configuration).to.equal(initialConfiguration);
    id<DVNTestPipelineStageModel> stage =
        (id<DVNTestPipelineStageModel>)configuration.samplingStageConfiguration;
    expect(stage.state).to.equal(0);
    stage = (id<DVNTestPipelineStageModel>)configuration.geometryStageConfiguration;
    expect(stage.state).to.equal(0);
    stage = (id<DVNTestPipelineStageModel>)configuration.textureStageConfiguration.model;
    expect(stage.state).to.equal(0);
    stage =
        (id<DVNTestPipelineStageModel>)configuration.attributeStageConfiguration.models.firstObject;
    expect(stage.state).to.equal(0);
  });
});

context(@"updating configuration", ^{
  it(@"should provide given configuration as current configuration after setting", ^{
    __block id<LTParameterizedObject> parameterizedObject =
        OCMProtocolMock(@protocol(LTParameterizedObject));
    LTTexture *renderTarget = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    [[[LTFbo alloc] initWithTexture:renderTarget] bindAndDraw:^{
      [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
    }];
    DVNPipelineConfiguration *configuration = pipeline.currentConfiguration;
    expect(configuration).toNot.equal(initialConfiguration);

    [pipeline setConfiguration:initialConfiguration];

    configuration = pipeline.currentConfiguration;
    expect(configuration).to.equal(initialConfiguration);
  });
});

context(@"processing", ^{
  __block id<LTParameterizedObject> parameterizedObject;
  __block LTTexture *renderTarget;
  __block LTFbo *fbo;

  beforeEach(^{
    parameterizedObject = OCMProtocolMock(@protocol(LTParameterizedObject));
    renderTarget = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    [renderTarget clearColor:LTVector4::ones()];
    fbo = [[LTFbo alloc] initWithTexture:renderTarget];
  });

  afterEach(^{
    fbo = nil;
    renderTarget = nil;
    parameterizedObject = nil;
  });

  context(@"rendering", ^{
    it(@"should correctly render", ^{
      [fbo bindAndDraw:^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
      }];
      expect($(renderTarget.image)).to.equalMat($(DVNTestSingleProcessResult()));
    });

    it(@"should correctly render across consecutive render calls", ^{
      [fbo bindAndDraw:^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
      }];
      expect($(renderTarget.image)).to.equalMat($(DVNTestConsecutiveProcessResult()));
    });
  });

  context(@"configuration", ^{
    it(@"should return an updated current configuration after processing", ^{
      [fbo bindAndDraw:^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
      }];
      DVNPipelineConfiguration *configuration = pipeline.currentConfiguration;
      expect(configuration).toNot.beNil();
      expect(configuration).toNot.equal(initialConfiguration);
      id<DVNTestPipelineStageModel> stage =
          (id<DVNTestPipelineStageModel>)configuration.samplingStageConfiguration;
      expect(stage.state).to.equal(1);
      stage = (id<DVNTestPipelineStageModel>)configuration.geometryStageConfiguration;
      expect(stage.state).to.equal(1);
      stage = (id<DVNTestPipelineStageModel>)configuration.textureStageConfiguration.model;
      expect(stage.state).to.equal(1);
      stage = (id<DVNTestPipelineStageModel>)
          configuration.attributeStageConfiguration.models.firstObject;
      expect(stage.state).to.equal(1);
    });

    it(@"should return an updated current configuration after consecutive processing", ^{
      [fbo bindAndDraw:^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
        lt::Interval<CGFloat> nextInterval({kInterval.sup(), kInterval.sup() + 1},
                                           lt::Interval<CGFloat>::EndpointInclusion::Open);
        [pipeline processParameterizedObject:parameterizedObject inInterval:nextInterval end:NO];
      }];
      DVNPipelineConfiguration *configuration = pipeline.currentConfiguration;
      expect(configuration).toNot.beNil();
      expect(configuration).toNot.equal(initialConfiguration);
      id<DVNTestPipelineStageModel> stage =
          (id<DVNTestPipelineStageModel>)configuration.samplingStageConfiguration;
      expect(stage.state).to.equal(2);
      stage = (id<DVNTestPipelineStageModel>)configuration.geometryStageConfiguration;
      expect(stage.state).to.equal(2);
      stage = (id<DVNTestPipelineStageModel>)configuration.textureStageConfiguration.model;
      expect(stage.state).to.equal(2);
      stage = (id<DVNTestPipelineStageModel>)
          configuration.attributeStageConfiguration.models.firstObject;
      expect(stage.state).to.equal(2);
    });
  });

  context(@"delegate", ^{
    it(@"should inform its delegate about a performed rendering", ^{
      id delegateMock = OCMProtocolMock(@protocol(DVNPipelineDelegate));
      OCMExpect([[delegateMock ignoringNonObjectArgs] pipeline:pipeline renderedQuads:{}]);
      pipeline.delegate = delegateMock;

      [fbo bindAndDraw:^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
      }];

      OCMVerifyAll(delegateMock);
    });
  });

  context(@"invalid calls", ^{
    it(@"should raise if attempting to execute without bound render target", ^{
      expect(^{
        [pipeline processParameterizedObject:parameterizedObject inInterval:kInterval end:NO];
      }).to.raise(kLTOpenGLRuntimeErrorException);
    });
  });
});

SpecEnd
