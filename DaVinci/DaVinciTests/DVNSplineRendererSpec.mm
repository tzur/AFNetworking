// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderer.h"

#import <LTEngine/LTBasicParameterizedObjectFactory.h>
#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNPipelineConfiguration.h"
#import "DVNSplineRenderModel.h"
#import "DVNTestPipelineConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

static NSString * const kDVNSplineRendererExamples = @"DVNSplineRendererExamples";
static NSString * const kDVNSplineRendererExamplesType = @"DVNSplineRendererExamplesType";
static NSString * const kDVNSplineRendererExamplesInsufficientControlPoints =
    @"DVNSplineRendererExamplesInsufficientControlPoints";
static NSString * const kDVNSplineRendererExamplesControlPoints =
    @"DVNSplineRendererExamplesControlPoints";
static NSString * const kDVNSplineRendererExamplesAdditionalControlPoints =
    @"DVNSplineRendererExamplesAdditionalControlPoints";

SharedExamplesBegin(DVNSplineRenderer)

sharedExamples(kDVNSplineRendererExamples, ^(NSDictionary *data) {
  __block LTParameterizedObjectType *type;
  __block NSArray<LTSplineControlPoint *> *insufficientControlPointsForRendering;
  __block NSArray<LTSplineControlPoint *> *controlPoints;
  __block NSArray<LTSplineControlPoint *> *additionalControlPoints;
  __block DVNPipelineConfiguration *initialConfiguration;

  beforeEach(^{
    type = data[kDVNSplineRendererExamplesType];
    insufficientControlPointsForRendering = data[kDVNSplineRendererExamplesInsufficientControlPoints];
    controlPoints = data[kDVNSplineRendererExamplesControlPoints];
    additionalControlPoints = data[kDVNSplineRendererExamplesAdditionalControlPoints];
    initialConfiguration = DVNTestPipelineConfiguration();
  });

  afterEach(^{
    initialConfiguration = nil;
    type = nil;
  });

  context(@"initialization", ^{
    it(@"should initialize correctly with all types of parameterized objects", ^{
      DVNSplineRenderer *renderer =
          [[DVNSplineRenderer alloc] initWithType:type
                                    configuration:initialConfiguration delegate:nil];
      expect(renderer).toNot.beNil();
    });
  });

  context(@"processing", ^{
    static const lt::Interval<CGFloat> kInterval({0, 1},
                                                 lt::Interval<CGFloat>::EndpointInclusion::Closed,
                                                 lt::Interval<CGFloat>::EndpointInclusion::Closed);

    __block id<LTParameterizedObject> parameterizedObject;
    __block DVNSplineRenderer *renderer;
    __block LTTexture *renderTarget;
    __block LTFbo *fbo;

    beforeEach(^{
      renderer = [[DVNSplineRenderer alloc] initWithType:type
                                           configuration:initialConfiguration delegate:nil];
      parameterizedObject = OCMProtocolMock(@protocol(LTParameterizedObject));
      renderTarget = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
      [renderTarget clearWithColor:LTVector4::ones()];
      fbo = [[LTFbo alloc] initWithTexture:renderTarget];
    });

    afterEach(^{
      controlPoints = nil;
      fbo = nil;
      renderTarget = nil;
      parameterizedObject = nil;
      renderer = nil;
      type = nil;
    });

    context(@"rendering", ^{
      it(@"should correctly render", ^{
        [fbo bindAndDraw:^{
          [renderer processControlPoints:controlPoints end:NO];
        }];
        expect($(renderTarget.image)).to.equalMat($(DVNTestSingleProcessResult()));
      });

      it(@"should correctly render across consecutive process calls", ^{
        [fbo bindAndDraw:^{
          [renderer processControlPoints:controlPoints end:NO];
          [renderer processControlPoints:additionalControlPoints end:NO];
        }];
        expect($(renderTarget.image)).to.equalMat($(DVNTestConsecutiveProcessResult()));
      });
    });

    context(@"delegate", ^{
      __block id delegateMock;

      beforeEach(^{
        delegateMock = OCMProtocolMock(@protocol(DVNSplineRendererDelegate));
        renderer = [[DVNSplineRenderer alloc] initWithType:type
                                             configuration:initialConfiguration
                                                  delegate:delegateMock];
      });

      afterEach(^{
        renderer = nil;
        delegateMock = nil;
      });

      context(@"start of rendering", ^{
        it(@"should not inform its delegate about processing but only about rendering", ^{
          id strictDelegateMock = OCMStrictProtocolMock(@protocol(DVNSplineRendererDelegate));
          renderer = [[DVNSplineRenderer alloc] initWithType:type
                                               configuration:initialConfiguration
                                                    delegate:strictDelegateMock];
          [fbo bindAndDraw:^{
            [renderer processControlPoints:insufficientControlPointsForRendering end:NO];
          }];
        });

        it(@"should inform its delegate about the start of a rendering", ^{
          OCMExpect([delegateMock renderingOfSplineRendererWillStart:renderer]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
          }];
          OCMVerifyAll(delegateMock);
        });

        it(@"should inform its delegate about the start of a rendering only once", ^{
          OCMExpect([delegateMock renderingOfSplineRendererWillStart:renderer]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
          }];
          OCMVerifyAll(delegateMock);

          [[delegateMock reject] renderingOfSplineRendererWillStart:[OCMArg any]];
          [fbo bindAndDraw:^{
            [renderer processControlPoints:additionalControlPoints end:NO];
          }];
          OCMVerifyAll(delegateMock);
        });
      });

      context(@"continuation of rendering", ^{
        it(@"should inform its delegate about the rendered quads", ^{
          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
          }];

          OCMVerifyAll(delegateMock);
        });

        it(@"should inform its delegate about the rendered quads, for every performed rendering", ^{
          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
          }];

          OCMVerifyAll(delegateMock);

          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:additionalControlPoints end:NO];
          }];

          OCMVerifyAll(delegateMock);
        });
      });

      context(@"end of rendering", ^{
        it(@"should inform its delegate about the render model after finishing a process sequence", ^{
          OCMExpect([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:YES];
          }];

          OCMVerifyAll(delegateMock);
        });

        context(@"render model", ^{
          it(@"should return correct model after finishing a simple process sequence", ^{
            OCMExpect([delegateMock
                       renderingOfSplineRenderer:renderer
                       endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
              expect(model).to.toNot.beNil();
              expect(model.controlPointModel.type).to.equal(type);
              expect(model.controlPointModel.controlPoints).to.equal(controlPoints);
              expect(model.configuration).to.equal(initialConfiguration);
              return YES;
            }]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:YES];
            }];

            OCMVerifyAll(delegateMock);
          });

          it(@"should return correct model after finishing a consecutive process sequence", ^{
            OCMExpect([delegateMock
                       renderingOfSplineRenderer:renderer
                       endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
              expect(model).to.toNot.beNil();
              expect(model.controlPointModel.type).to.equal(type);
              expect(model.controlPointModel.controlPoints)
                  .to.equal([controlPoints arrayByAddingObjectsFromArray:additionalControlPoints]);
              expect(model.configuration).to.equal(initialConfiguration);
              return YES;
            }]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
              [renderer processControlPoints:additionalControlPoints end:YES];
            }];

            OCMVerifyAll(delegateMock);
          });

          it(@"should return correct model after processing, following previous processing", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:YES];
            }];

            OCMExpect([delegateMock
                       renderingOfSplineRenderer:renderer
                       endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
              expect(model).to.toNot.beNil();
              expect(model.controlPointModel.type).to.equal(type);
              expect(model.controlPointModel.controlPoints).to.equal(controlPoints);
              DVNPipelineConfiguration *configuration = model.configuration;
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
              return YES;
            }]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:YES];
            }];

            OCMVerifyAll(delegateMock);
          });
        });
      });
    });

    context(@"rendering with render model", ^{
      __block id delegateMock;

      beforeEach(^{
        delegateMock = OCMProtocolMock(@protocol(DVNSplineRendererDelegate));
        renderer = [[DVNSplineRenderer alloc] initWithType:type
                                             configuration:initialConfiguration
                                                  delegate:delegateMock];
      });

      afterEach(^{
        renderer = nil;
        delegateMock = nil;
      });

      it(@"should correctly render using a given render model", ^{
        __block DVNSplineRenderModel *renderModel;

        OCMExpect([delegateMock
                   renderingOfSplineRenderer:renderer
                   endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
          renderModel = model;
          return YES;
        }]]);

        [fbo bindAndDraw:^{
          [renderer processControlPoints:controlPoints end:YES];
        }];

        [renderTarget clearWithColor:LTVector4::ones()];
        cv::Mat4b expectedMat = DVNTestSingleProcessResult();
        expect($(renderTarget.image)).toNot.equalMat($(expectedMat));

        [fbo bindAndDraw:^{
          [DVNSplineRenderer processModel:renderModel];
        }];

        expect($(renderTarget.image)).to.equalMat($(expectedMat));
      });


      it(@"should correctly render using a given render model requiring two render passes", ^{
        __block DVNSplineRenderModel *renderModel;

        OCMExpect([delegateMock
                   renderingOfSplineRenderer:renderer
                   endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
          renderModel = model;
          return YES;
        }]]);

        [fbo bindAndDraw:^{
          [renderer processControlPoints:controlPoints end:NO];
          [renderer processControlPoints:additionalControlPoints end:YES];
        }];

        [renderTarget clearWithColor:LTVector4::ones()];
        cv::Mat4b expectedMat = DVNTestConsecutiveProcessResult();
        expect($(renderTarget.image)).toNot.equalMat($(expectedMat));

        [fbo bindAndDraw:^{
          [DVNSplineRenderer processModel:renderModel];
        }];

        expect($(renderTarget.image)).to.equalMat($(expectedMat));
      });
    });

    context(@"invalid calls", ^{
      it(@"should raise if attempting to execute without bound render target", ^{
        expect(^{
          [renderer processControlPoints:controlPoints end:NO];
        }).to.raise(kLTOpenGLRuntimeErrorException);
      });

      it(@"should raise if attempting to process render model without bound render target", ^{
        id delegateMock = OCMProtocolMock(@protocol(DVNSplineRendererDelegate));
        renderer = [[DVNSplineRenderer alloc] initWithType:type
                                             configuration:initialConfiguration
                                                  delegate:delegateMock];

        __block DVNSplineRenderModel *renderModel;

        OCMExpect([delegateMock
                   renderingOfSplineRenderer:renderer
                   endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
          renderModel = model;
          return YES;
        }]]);

        [fbo bindAndDraw:^{
          [renderer processControlPoints:controlPoints end:YES];
        }];

        expect(^{
          [DVNSplineRenderer processModel:renderModel];
        }).to.raise(kLTOpenGLRuntimeErrorException);
      });
    });
  });
});

SharedExamplesEnd

NSDictionary<NSString *, id> *DVNTestDictionaryForType(LTParameterizedObjectType *type) {
  NSArray<LTSplineControlPoint *> *insufficientControlPointsForRendering =
      @[[[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero]];

  NSUInteger numberOfRequiredControlPoints = [[[type factory] class] numberOfRequiredValues];

  NSMutableArray<LTSplineControlPoint *> *mutableControlPoints =
      [NSMutableArray arrayWithCapacity:numberOfRequiredControlPoints];
  for (NSUInteger i = 0; i < numberOfRequiredControlPoints; ++i) {
    [mutableControlPoints addObject:[[LTSplineControlPoint alloc]
                                     initWithTimestamp:i location:CGPointMake(i, i + 1)]];
  }
  NSArray<LTSplineControlPoint *> *controlPoints = [mutableControlPoints copy];

  [mutableControlPoints removeAllObjects];
  for (NSUInteger i = 0; i < numberOfRequiredControlPoints; ++i) {
    [mutableControlPoints addObject:[[LTSplineControlPoint alloc]
                                     initWithTimestamp:numberOfRequiredControlPoints + i
                                     location:CGPointMake(numberOfRequiredControlPoints + i,
                                                          numberOfRequiredControlPoints + i + 1)]];
  }
  NSArray<LTSplineControlPoint *> *additionalControlPoints = [mutableControlPoints copy];

  return @{
    kDVNSplineRendererExamplesType: type,
    kDVNSplineRendererExamplesInsufficientControlPoints: insufficientControlPointsForRendering,
    kDVNSplineRendererExamplesControlPoints: controlPoints,
    kDVNSplineRendererExamplesAdditionalControlPoints: additionalControlPoints
  };
}

SpecBegin(DVNSplineRenderer)

context(@"spline renderer", ^{
  it(@"should work correctly for all types", ^{
    [LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *type) {
      itShouldBehaveLike(kDVNSplineRendererExamples, ^{
        return DVNTestDictionaryForType(type);
      });
    }];
  });
});

SpecEnd
