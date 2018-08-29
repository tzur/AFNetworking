// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNSplineRenderer.h"

#import <LTEngine/LTBasicParameterizedObjectFactory.h>
#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNPipeline.h"
#import "DVNPipelineConfiguration.h"
#import "DVNSplineRenderModel.h"
#import "DVNSplineRenderingExamples.h"
#import "DVNTestPipelineConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

static NSString * const kDVNSplineRendererExamples = @"DVNSplineRendererExamples";

@interface DVNSplineRenderer ()
@property (readonly, nonatomic) DVNPipeline *pipeline;
@end

SharedExamplesBegin(DVNSplineRenderer)

sharedExamples(kDVNSplineRendererExamples, ^(NSDictionary *values) {
  __block LTParameterizedObjectType *type;
  __block NSArray<LTSplineControlPoint *> *insufficientControlPointsForRendering;
  __block NSArray<LTSplineControlPoint *> *controlPoints;
  __block NSArray<LTSplineControlPoint *> *additionalControlPoints;
  __block DVNPipelineConfiguration *initialConfiguration;

  beforeEach(^{
    type = values[kDVNSplineRenderingExamplesType];
    insufficientControlPointsForRendering =
        values[kDVNSplineRenderingExamplesInsufficientControlPoints];
    controlPoints = values[kDVNSplineRenderingExamplesControlPoints];
    additionalControlPoints = values[kDVNSplineRenderingExamplesAdditionalControlPoints];
    initialConfiguration = values[kDVNSplineRenderingExamplesPipelineConfiguration];
  });

  context(@"state-preserving processing", ^{
    __block id<LTParameterizedObject> parameterizedObject;
    __block DVNSplineRenderer *renderer;
    __block LTTexture *renderTarget;
    __block LTFbo *fbo;
    __block cv::Mat initialMat;
    __block cv::Mat expectedMatForSingleRenderCall;
    __block cv::Mat expectedMatForConsecutiveRenderCalls;

    beforeEach(^{
      renderer = values[kDVNSplineRenderingExamplesRendererWithoutDelegate];
      parameterizedObject = OCMProtocolMock(@protocol(LTParameterizedObject));
      renderTarget = values[kDVNSplineRenderingExamplesTexture];
      [renderTarget clearColor:LTVector4::ones()];
      fbo = [[LTFbo alloc] initWithTexture:renderTarget];
      initialMat = renderTarget.image;
      expectedMatForSingleRenderCall = DVNTestSingleProcessResult();
      expectedMatForConsecutiveRenderCalls = DVNTestConsecutiveProcessResult();
    });

    context(@"rendering", ^{
      context(@"single render pass", ^{
        it(@"should not render for process call without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should render before terminating process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for simple process sequence", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for process sequence without control points in last process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for process sequence without control points in first process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:NO];
            [renderer processControlPoints:controlPoints preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        context(@"single point rendering", ^{
          it(@"should render a single point for process sequence with insufficient points", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering preserveState:YES
                                         end:YES];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
          });

          it(@"should render a single point for split process sequence with insufficient points", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering preserveState:NO
                                         end:NO];
              [renderer processControlPoints:@[] preserveState:YES end:YES];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
          });
        });
      });

      context(@"consecutive render pass", ^{
        it(@"should render across consecutive process calls", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });

        it(@"should render across consecutive process calls and reset the used spline", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render across consecutive process calls with announced end", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });

        it(@"should render across consecutive process calls with end announced without points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            [renderer processControlPoints:additionalControlPoints preserveState:NO end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });
      });

      context(@"no rendering", ^{
        it(@"should not render for simple process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequences without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:YES];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });
      });
    });

    context(@"state preserving", ^{
      context(@"single render pass", ^{
        it(@"should preserve state for process call without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:NO];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state when rendering before terminating process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state when rendering simple process sequence", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state when rendering without control points in last process call", ^{
          __block DVNPipelineConfiguration *configuration;
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            configuration = renderer.pipeline.currentConfiguration;
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(configuration);
        });

        it(@"should preserve state when rendering without control points in first process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:NO];
            [renderer processControlPoints:controlPoints preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        context(@"single point rendering", ^{
          it(@"should preserve state when rendering single point", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering preserveState:YES
                                         end:YES];
            }];
            expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
          });

          it(@"should preserve state when rendering single point for split process sequence", ^{
            __block DVNPipelineConfiguration *configuration;
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering preserveState:NO
                                         end:NO];
              configuration = renderer.pipeline.currentConfiguration;
              [renderer processControlPoints:@[] preserveState:YES end:YES];
            }];
            expect(renderer.pipeline.currentConfiguration).to.equal(configuration);
          });
        });
      });

      context(@"consecutive render pass", ^{
        it(@"should preserve state when rendering across consecutive process calls", ^{
          __block DVNPipelineConfiguration *configuration;
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            configuration = renderer.pipeline.currentConfiguration;
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(configuration);
        });

        it(@"should preserve state when rendering across consecutive process calls with end", ^{
          __block DVNPipelineConfiguration *configuration;
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            configuration = renderer.pipeline.currentConfiguration;
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(configuration);
        });

        it(@"should preserve state when rendering across consecutive empty process calls with end",
           ^{
          __block DVNPipelineConfiguration *configuration;
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:NO end:NO];
            [renderer processControlPoints:additionalControlPoints preserveState:NO end:NO];
            configuration = renderer.pipeline.currentConfiguration;
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(configuration);
        });
      });

      context(@"no rendering", ^{
        it(@"should preserve state when not rendering due to lack of control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });

        it(@"should preserve state for process sequences without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:NO end:YES];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
          expect(renderer.pipeline.currentConfiguration).to.equal(initialConfiguration);
        });
      });
    });

    context(@"delegate", ^{
      __block id delegateMock;

      beforeEach(^{
        delegateMock = values[kDVNSplineRenderingExamplesDelegateMock];
        renderer = values[kDVNSplineRenderingExamplesRendererWithDelegate];
      });

      afterEach(^{
        renderer = nil;
        delegateMock = nil;
      });

      context(@"start of rendering", ^{
        it(@"should not inform its delegate about processing but only about rendering", ^{
          DVNSplineRenderer *rendererWithStrictDelegate =
              values[kDVNSplineRenderingExamplesRendererWithStrictDelegate];
          [fbo bindAndDraw:^{
            [rendererWithStrictDelegate processControlPoints:@[] preserveState:YES end:YES];
          }];

          [fbo bindAndDraw:^{
            [rendererWithStrictDelegate processControlPoints:insufficientControlPointsForRendering
                                               preserveState:YES end:NO];
          }];
        });

        it(@"should inform its delegate about the start of a rendering", ^{
          OCMExpect([delegateMock renderingOfSplineRendererWillStart:renderer]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];
          OCMVerifyAll(delegateMock);
        });

        it(@"should inform its delegate about the start of a rendering only once", ^{
          OCMExpect([delegateMock renderingOfSplineRendererWillStart:renderer]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];
          OCMVerifyAll(delegateMock);

          OCMReject([delegateMock renderingOfSplineRendererWillStart:OCMOCK_ANY]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
          }];
        });
      });

      context(@"continuation of rendering", ^{
        it(@"should inform its delegate about the rendered quads", ^{
          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];

          OCMVerifyAll(delegateMock);
        });

        it(@"should inform its delegate about the rendered quads, for every performed rendering", ^{
          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
          }];

          OCMVerifyAll(delegateMock);

          OCMExpect([[delegateMock ignoringNonObjectArgs] renderingOfSplineRenderer:renderer
                                                                 continuedWithQuads:{}]);

          [fbo bindAndDraw:^{
            [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
          }];

          OCMVerifyAll(delegateMock);
        });
      });

      context(@"end of rendering", ^{
        it(@"should not inform delegate after finishing process sequence", ^{
          OCMReject([delegateMock renderingOfSplineRenderer:OCMOCK_ANY endedWithModel:OCMOCK_ANY]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:YES];
          }];

          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints preserveState:YES end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
        });

        it(@"should not inform delegate after finishing single point process sequence", ^{
          OCMReject([delegateMock renderingOfSplineRenderer:OCMOCK_ANY endedWithModel:OCMOCK_ANY]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:insufficientControlPointsForRendering preserveState:YES
                                       end:YES];
          }];

          OCMReject([delegateMock renderingOfSplineRenderer:OCMOCK_ANY endedWithModel:OCMOCK_ANY]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:insufficientControlPointsForRendering preserveState:YES
                                       end:NO];
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
        });

        it(@"should not inform delegate after finishing process sequence without point", ^{
          OCMReject([delegateMock renderingOfSplineRenderer:OCMOCK_ANY endedWithModel:OCMOCK_ANY]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] preserveState:YES end:YES];
          }];
        });
      });
    });

    context(@"cancellation", ^{
      context(@"rendering", ^{
        context(@"single render pass before cancellation", ^{
          context(@"without announced end", ^{
            it(@"should correctly render", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:YES end:NO];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });

            it(@"should not render if cancellation occurs", ^{
              cv::Mat expectedImage = renderTarget.image;

              [fbo bindAndDraw:^{
                [renderer processControlPoints:insufficientControlPointsForRendering
                                 preserveState:YES end:NO];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedImage));
            });
          });

          context(@"announced end", ^{
            it(@"should correctly render with announced end", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:YES end:YES];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });

            it(@"should render if cancellation occurs after final rendering", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:insufficientControlPointsForRendering
                                 preserveState:YES end:YES];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });
          });
        });

        context(@"consecutive render pass before cancellation", ^{
          it(@"should correctly render across consecutive process calls", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints preserveState:NO end:NO];
              [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
            }];
            [renderer cancel];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });

          it(@"should correctly render across consecutive process calls with announced end", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints preserveState:NO end:NO];
              [renderer processControlPoints:additionalControlPoints preserveState:YES end:YES];
            }];
            [renderer cancel];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });
        });

        context(@"consecutive render pass with interleaved cancellation", ^{
          it(@"should correctly render across consecutive process calls", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints preserveState:NO end:NO];
              [renderer cancel];
              [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });

          it(@"should correctly render across consecutive process calls with announced end", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints preserveState:NO end:NO];
              [renderer cancel];
              [renderer processControlPoints:additionalControlPoints preserveState:YES end:YES];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });
        });
      });

      context(@"delegate", ^{
        __block id delegateMock;

        beforeEach(^{
          delegateMock = values[kDVNSplineRenderingExamplesDelegateMock];
          renderer = values[kDVNSplineRenderingExamplesRendererWithDelegate];
        });

        afterEach(^{
          renderer = nil;
          delegateMock = nil;
        });

        context(@"end of rendering", ^{
          it(@"should not inform its delegate if no rendering was performed before cancellation", ^{
            DVNSplineRenderer *rendererWithStrictDelegate =
                values[kDVNSplineRenderingExamplesRendererWithStrictDelegate];

            [fbo bindAndDraw:^{
              [rendererWithStrictDelegate processControlPoints:insufficientControlPointsForRendering
                                                 preserveState:YES end:NO];
            }];
            [rendererWithStrictDelegate cancel];

            [fbo bindAndDraw:^{
              [rendererWithStrictDelegate processControlPoints:@[] preserveState:YES end:YES];
            }];
            [rendererWithStrictDelegate cancel];
          });

          context(@"render model", ^{
            it(@"should return correct model after finishing a simple process sequence", ^{
              OCMExpect([delegateMock
                         renderingOfSplineRenderer:renderer
                         endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
                expect(model).to.toNot.beNil();
                expect(model.controlPointModel.type).to.equal(type);
                expect(model.controlPointModel.controlPoints).to.haveACountOf(0);
                expect(model.configuration).to.equal(initialConfiguration);
                return YES;
              }]]);

              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:YES end:NO];
                [renderer cancel];
              }];

              OCMVerifyAll(delegateMock);
            });

            it(@"should return correct model after finishing a consecutive process sequence", ^{
              OCMExpect([delegateMock
                         renderingOfSplineRenderer:renderer
                         endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
                expect(model).toNot.beNil();
                expect(model.controlPointModel.type).to.equal(type);
                expect(model.controlPointModel.controlPoints).to.haveACountOf(0);
                expect(model.configuration).to.equal(initialConfiguration);
                return YES;
              }]]);

              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:YES end:NO];
                [renderer processControlPoints:additionalControlPoints preserveState:YES end:NO];
                [renderer cancel];
              }];

              OCMVerifyAll(delegateMock);
            });

            it(@"should return correct model after processing, following previous processing", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:NO end:YES];
              }];

              OCMExpect([delegateMock
                         renderingOfSplineRenderer:renderer
                         endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
                expect(model).to.toNot.beNil();
                expect(model.controlPointModel.type).to.equal(type);
                expect(model.controlPointModel.controlPoints).to.haveACountOf(0);
                DVNPipelineConfiguration *configuration = model.configuration;
                expect(configuration).toNot.equal(initialConfiguration);
                id<DVNTestPipelineStageModel> stage =
                    (id<DVNTestPipelineStageModel>)configuration.samplingStageConfiguration;
                expect(stage.state).to.equal(1);
                stage = (id<DVNTestPipelineStageModel>)configuration.geometryStageConfiguration;
                expect(stage.state).to.equal(1);
                stage =
                    (id<DVNTestPipelineStageModel>)configuration.textureStageConfiguration.model;
                expect(stage.state).to.equal(1);
                stage = (id<DVNTestPipelineStageModel>)
                    configuration.attributeStageConfiguration.models.firstObject;
                expect(stage.state).to.equal(1);
                return YES;
              }]]);

              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints preserveState:YES end:NO];
                [renderer cancel];
              }];

              OCMVerifyAll(delegateMock);
            });
          });
        });
      });
    });
  });
});

SharedExamplesEnd

SpecBegin(DVNSplineRenderer)

[LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *type) {
  if ([type isEqual:$(LTParameterizedObjectTypeDegenerate)]) {
    return;
  }

  itShouldBehaveLike(kDVNSplineRenderingExamples, ^{
    NSMutableDictionary *dictionary = [DVNTestDictionaryForType(type) mutableCopy];
    id<DVNSplineRenderingDelegate> delegate =
        OCMProtocolMock(@protocol(DVNSplineRenderingDelegate));
    id<DVNSplineRenderingDelegate> strictDelegate =
        OCMStrictProtocolMock(@protocol(DVNSplineRenderingDelegate));
    DVNPipelineConfiguration *configuration = DVNTestPipelineConfiguration();

    dictionary[kDVNSplineRenderingExamplesPipelineConfiguration] = configuration;
    dictionary[kDVNSplineRenderingExamplesRendererWithoutDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:nil];
    dictionary[kDVNSplineRenderingExamplesRendererWithDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:delegate];
    dictionary[kDVNSplineRenderingExamplesRendererWithStrictDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:strictDelegate];
    dictionary[kDVNSplineRenderingExamplesStrictDelegateMock] = strictDelegate;
    dictionary[kDVNSplineRenderingExamplesTexture] =
        [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    dictionary[kDVNSplineRenderingExamplesDelegateMock] = delegate;
    return dictionary;
  });
}];

[LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *type) {
  if ([type isEqual:$(LTParameterizedObjectTypeDegenerate)]) {
    return;
  }

  itShouldBehaveLike(kDVNSplineRendererExamples, ^{
    NSMutableDictionary *dictionary = [DVNTestDictionaryForType(type) mutableCopy];
    id<DVNSplineRenderingDelegate> delegate =
        OCMProtocolMock(@protocol(DVNSplineRenderingDelegate));
    id<DVNSplineRenderingDelegate> strictDelegate =
        OCMStrictProtocolMock(@protocol(DVNSplineRenderingDelegate));
    DVNPipelineConfiguration *configuration = DVNTestPipelineConfiguration();

    dictionary[kDVNSplineRenderingExamplesPipelineConfiguration] = configuration;
    dictionary[kDVNSplineRenderingExamplesRendererWithoutDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:nil];
    dictionary[kDVNSplineRenderingExamplesRendererWithDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:delegate];
    dictionary[kDVNSplineRenderingExamplesRendererWithStrictDelegate] =
        [[DVNSplineRenderer alloc] initWithType:dictionary[kDVNSplineRenderingExamplesType]
                                  configuration:configuration delegate:strictDelegate];
    dictionary[kDVNSplineRenderingExamplesStrictDelegateMock] = strictDelegate;
    dictionary[kDVNSplineRenderingExamplesTexture] =
        [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(16)];
    dictionary[kDVNSplineRenderingExamplesDelegateMock] = delegate;

    return dictionary;
  });
}];

SpecEnd
