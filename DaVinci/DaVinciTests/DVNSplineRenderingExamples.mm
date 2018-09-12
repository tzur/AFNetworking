// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderingExamples.h"

#import <LTEngine/LTBasicParameterizedObjectFactory.h>
#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTFbo.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture.h>

#import "DVNAttributeStageConfiguration.h"
#import "DVNPipelineConfiguration.h"
#import "DVNSplineRenderModel.h"
#import "DVNSplineRendering.h"
#import "DVNTestPipelineConfiguration.h"
#import "DVNTextureMappingStageConfiguration.h"

NSString * const kDVNSplineRenderingExamples = @"DVNSplineRenderingExamples";
NSString * const kDVNSplineRenderingExamplesTexture = @"DVNSplineRenderingExamplesTexture";
NSString * const kDVNSplineRenderingExamplesDelegateMock =
    @"DVNSplineRenderingExamplesDelegateMock";
NSString * const kDVNSplineRenderingExamplesStrictDelegateMock =
    @"DVNSplineRenderingExamplesStrictDelegateMock";
NSString * const kDVNSplineRenderingExamplesRendererWithoutDelegate =
    @"DVNSplineRenderingExamplesRendererWithoutDelegate";
NSString * const kDVNSplineRenderingExamplesRendererWithDelegate =
    @"DVNSplineRenderingExamplesRendererWithDelegate";
NSString * const kDVNSplineRenderingExamplesRendererWithStrictDelegate =
    @"DVNSplineRenderingExamplesRendererWithStrictDelegate";
NSString * const kDVNSplineRenderingExamplesType = @"DVNSplineRenderingExamplesType";
NSString * const kDVNSplineRenderingExamplesInsufficientControlPoints =
    @"DVNSplineRenderingExamplesExamplesInsufficientControlPoints";
NSString * const kDVNSplineRenderingExamplesControlPoints =
    @"DVNSplineRenderingExamplesControlPoints";
NSString * const kDVNSplineRenderingExamplesAdditionalControlPoints =
    @"DVNSplineRenderingExamplesAdditionalControlPoints";
NSString * const kDVNSplineRenderingExamplesPipelineConfiguration =
    @"DVNSplineRenderingExamplesPipelineConfiguration";

SharedExamplesBegin(DVNSplineRendering)

sharedExamples(kDVNSplineRenderingExamples, ^(NSDictionary *values) {
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

  context(@"processing", ^{
    __block id<LTParameterizedObject> parameterizedObject;
    __block id<DVNSplineRendering> renderer;
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

    afterEach(^{
      controlPoints = nil;
      fbo = nil;
      renderTarget = nil;
      parameterizedObject = nil;
      renderer = nil;
      type = nil;
    });

    context(@"rendering", ^{
      context(@"single render pass", ^{
        it(@"should not render for process call without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should render before terminating process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for simple process sequence", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for process sequence without control points in last process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        it(@"should render for process sequence without control points in first process call", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:NO];
            [renderer processControlPoints:controlPoints end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
        });

        context(@"single point rendering", ^{
          it(@"should render a single point for process sequence with insufficient points", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering end:YES];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
          });

          it(@"should render a single point for split process sequence with insufficient points", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering end:NO];
              [renderer processControlPoints:@[] end:YES];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
          });
        });
      });

      context(@"consecutive render pass", ^{
        it(@"should render across consecutive process calls", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
            [renderer processControlPoints:additionalControlPoints end:NO];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });

        it(@"should render across consecutive process calls with announced end", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
            [renderer processControlPoints:additionalControlPoints end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });

        it(@"should render across consecutive process calls with end announced without points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
            [renderer processControlPoints:additionalControlPoints end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
        });
      });

      context(@"no rendering", ^{
        it(@"should not render for simple process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequence without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
        });

        it(@"should not render for process sequences without control points", ^{
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:YES];
            [renderer processControlPoints:@[] end:YES];
          }];
          expect($(renderTarget.image)).to.equalMat($(initialMat));
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
          id strictDelegateMock = values[kDVNSplineRenderingExamplesStrictDelegateMock];
          id<DVNSplineRendering> rendererWithStrictDelegate =
              values[kDVNSplineRenderingExamplesRendererWithStrictDelegate];
          [fbo bindAndDraw:^{
            [rendererWithStrictDelegate processControlPoints:@[] end:YES];
          }];

          [fbo bindAndDraw:^{
            [rendererWithStrictDelegate processControlPoints:insufficientControlPointsForRendering
                                                         end:NO];
          }];

          OCMVerifyAll(strictDelegateMock);
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
        it(@"should inform delegate about render model after finishing process sequence", ^{
          OCMExpect([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:YES];
          }];
          OCMVerifyAll(delegateMock);

          OCMExpect([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:controlPoints end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          OCMVerifyAll(delegateMock);
        });

        it(@"should inform delegate about model after finishing single point process sequence", ^{
          OCMExpect([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:insufficientControlPointsForRendering end:YES];
          }];
          OCMVerifyAll(delegateMock);

          OCMExpect([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:insufficientControlPointsForRendering end:NO];
            [renderer processControlPoints:@[] end:YES];
          }];
          OCMVerifyAll(delegateMock);
        });

        it(@"should not inform delegate about model after finishing process sequence without point",
           ^{
          OCMReject([delegateMock renderingOfSplineRenderer:renderer endedWithModel:[OCMArg any]]);
          [fbo bindAndDraw:^{
            [renderer processControlPoints:@[] end:YES];
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

          it(@"should return correct model after finishing a single point process sequence", ^{
            NSUInteger numberOfRequiredControlPoints =
                [[[type factory] class] numberOfRequiredValues];

            NSMutableArray<LTSplineControlPoint *> *expectedControlPoints =
                [NSMutableArray arrayWithCapacity:numberOfRequiredControlPoints];
            for (NSUInteger i = 0; i < numberOfRequiredControlPoints; ++i) {
              [expectedControlPoints addObject:insufficientControlPointsForRendering.firstObject];
            }

            OCMExpect([delegateMock
                       renderingOfSplineRenderer:renderer
                       endedWithModel:[OCMArg checkWithBlock:^BOOL(DVNSplineRenderModel *model) {
              expect(model).to.toNot.beNil();
              expect(model.controlPointModel.type).to.equal(type);
              expect(model.controlPointModel.controlPoints).to.equal(expectedControlPoints);
              expect(model.configuration).to.equal(initialConfiguration);
              return YES;
            }]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:insufficientControlPointsForRendering end:YES];
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

    context(@"cancellation", ^{
      context(@"rendering", ^{
        context(@"single render pass before cancellation", ^{
          context(@"without announced end", ^{
            it(@"should correctly render", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints end:NO];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });

            it(@"should not render if cancellation occurs", ^{
              cv::Mat expectedImage = renderTarget.image;

              [fbo bindAndDraw:^{
                [renderer processControlPoints:insufficientControlPointsForRendering end:NO];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedImage));
            });
          });

          context(@"announced end", ^{
            it(@"should correctly render with announced end", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints end:YES];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });

            it(@"should render if cancellation occurs after final rendering", ^{
              [fbo bindAndDraw:^{
                [renderer processControlPoints:insufficientControlPointsForRendering end:YES];
              }];
              [renderer cancel];
              expect($(renderTarget.image)).to.equalMat($(expectedMatForSingleRenderCall));
            });
          });
        });

        context(@"consecutive render pass before cancellation", ^{
          it(@"should correctly render across consecutive process calls", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
              [renderer processControlPoints:additionalControlPoints end:NO];
            }];
            [renderer cancel];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });

          it(@"should correctly render across consecutive process calls with announced end", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
              [renderer processControlPoints:additionalControlPoints end:YES];
            }];
            [renderer cancel];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });
        });

        context(@"consecutive render pass with interleaved cancellation", ^{
          it(@"should correctly render across consecutive process calls", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
              [renderer cancel];
              [renderer processControlPoints:additionalControlPoints end:NO];
            }];
            expect($(renderTarget.image)).to.equalMat($(expectedMatForConsecutiveRenderCalls));
          });

          it(@"should correctly render across consecutive process calls with announced end", ^{
            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
              [renderer cancel];
              [renderer processControlPoints:additionalControlPoints end:YES];
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
            id strictDelegateMock = values[kDVNSplineRenderingExamplesStrictDelegateMock];
            id<DVNSplineRendering> rendererWithStrictDelegate =
                values[kDVNSplineRenderingExamplesRendererWithStrictDelegate];

            [fbo bindAndDraw:^{
              [rendererWithStrictDelegate processControlPoints:insufficientControlPointsForRendering
                                                           end:NO];
            }];
            [rendererWithStrictDelegate cancel];

            [fbo bindAndDraw:^{
              [rendererWithStrictDelegate processControlPoints:@[] end:YES];
            }];
            [rendererWithStrictDelegate cancel];

            OCMVerifyAll(strictDelegateMock);
          });

          it(@"should inform its delegate if rendering was performed before cancellation", ^{
            OCMExpect([delegateMock renderingOfSplineRenderer:renderer
                                               endedWithModel:[OCMArg any]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:NO];
            }];
            [renderer cancel];

            OCMVerifyAll(delegateMock);
          });

          it(@"should inform its delegate once if rendering was performed before cancellation", ^{
            OCMExpect([delegateMock renderingOfSplineRenderer:renderer
                                               endedWithModel:[OCMArg any]]);

            [fbo bindAndDraw:^{
              [renderer processControlPoints:controlPoints end:YES];
            }];

            OCMVerifyAll(delegateMock);

            OCMReject([delegateMock renderingOfSplineRenderer:[OCMArg any]
                                               endedWithModel:[OCMArg any]]);
            [renderer cancel];
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
                [renderer processControlPoints:controlPoints end:NO];
                [renderer cancel];
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
                    .to.equal([controlPoints
                               arrayByAddingObjectsFromArray:additionalControlPoints]);
                expect(model.configuration).to.equal(initialConfiguration);
                return YES;
              }]]);

              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints end:NO];
                [renderer processControlPoints:additionalControlPoints end:NO];
                [renderer cancel];
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
                stage =
                    (id<DVNTestPipelineStageModel>)configuration.textureStageConfiguration.model;
                expect(stage.state).to.equal(1);
                stage = (id<DVNTestPipelineStageModel>)
                    configuration.attributeStageConfiguration.models.firstObject;
                expect(stage.state).to.equal(1);
                return YES;
              }]]);

              [fbo bindAndDraw:^{
                [renderer processControlPoints:controlPoints end:NO];
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

NSDictionary<NSString *, id> *DVNTestDictionaryForType(LTParameterizedObjectType *type) {
  NSArray<LTSplineControlPoint *> *insufficientControlPointsForRendering =
      @[[[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero]];

  NSUInteger numberOfRequiredControlPoints = [[[type factory] class] numberOfRequiredValues];

  NSMutableArray<LTSplineControlPoint *> *mutableControlPoints =
      [NSMutableArray arrayWithCapacity:numberOfRequiredControlPoints];
  for (NSUInteger i = 0; i < numberOfRequiredControlPoints; ++i) {
    [mutableControlPoints addObject:[[LTSplineControlPoint alloc]
                                     initWithTimestamp:i + 1 location:CGPointMake(i, i + 1)]];
  }
  NSArray<LTSplineControlPoint *> *controlPoints = [mutableControlPoints copy];

  [mutableControlPoints removeAllObjects];
  for (NSUInteger i = 0; i < numberOfRequiredControlPoints; ++i) {
    [mutableControlPoints addObject:[[LTSplineControlPoint alloc]
                                     initWithTimestamp:numberOfRequiredControlPoints + i + 1
                                     location:CGPointMake(numberOfRequiredControlPoints + i,
                                                          numberOfRequiredControlPoints + i + 1)]];
  }
  NSArray<LTSplineControlPoint *> *additionalControlPoints = [mutableControlPoints copy];

  return @{
    kDVNSplineRenderingExamplesType: type,
    kDVNSplineRenderingExamplesInsufficientControlPoints: insufficientControlPointsForRendering,
    kDVNSplineRenderingExamplesControlPoints: controlPoints,
    kDVNSplineRenderingExamplesAdditionalControlPoints: additionalControlPoints
  };
}
