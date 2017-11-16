// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryProviderModel.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>
#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProviderExamples.h"
#import "DVNTestGeometryProvider.h"

SpecBegin(DVNScatteredGeometryProviderModel)

__block id<LTSampleValues> samples;
__block DVNTestGeometryProviderModel *underlyingProviderModel;
__block LTRandomState *randomState;
__block lt::Interval<NSUInteger> count;
__block lt::Interval<CGFloat> distance;
__block lt::Interval<CGFloat> angle;
__block lt::Interval<CGFloat> scale;
__block DVNScatteredGeometryProviderModel *model;

beforeEach(^{
  underlyingProviderModel = [[DVNTestGeometryProviderModel alloc] initWithState:0];
  randomState = [[LTRandom alloc] init].engineState;
  count = lt::Interval<NSUInteger>({300, 500}, lt::Interval<NSUInteger>::EndpointInclusion::Closed);
  distance = lt::Interval<CGFloat>({1, 5}, lt::Interval<CGFloat>::EndpointInclusion::Closed);
  angle = lt::Interval<CGFloat>({M_PI_4, M_PI}, lt::Interval<CGFloat>::EndpointInclusion::Closed);
  scale = lt::Interval<CGFloat>({0.5, 1.5}, lt::Interval<CGFloat>::EndpointInclusion::Closed);

  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[@"xKey", @"yKey"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];

  model = [[DVNScatteredGeometryProviderModel alloc]
           initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
           count:count distance:distance angle:angle scale:scale];
});

afterEach(^{
  samples = nil;
  model = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
    expect(model.geometryProviderModel).to.equal(underlyingProviderModel);
    expect(model.randomState).to.equal(randomState);
    expect(model.count == count).to.beTruthy();
    expect(model.distance == distance).to.beTruthy();
    expect(model.angle == angle).to.beTruthy();
    expect(model.scale == scale).to.beTruthy();
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNScatteredGeometryProviderModel *model = [[DVNScatteredGeometryProviderModel alloc]
                                              initWithGeometryProviderModel:underlyingProviderModel
                                              randomState:randomState count:count distance:distance
                                              angle:angle scale:scale];
  DVNScatteredGeometryProviderModel *equalModel =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale];
  lt::Interval<NSUInteger> differentCount =
      lt::Interval<NSUInteger>({200, 300}, lt::Interval<NSUInteger>::EndpointInclusion::Closed);
  DVNScatteredGeometryProviderModel *differentModel =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
       count:differentCount distance:distance angle:angle scale:scale];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[differentModel]
  };
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  DVNScatteredGeometryProviderModel *model = [[DVNScatteredGeometryProviderModel alloc]
                                              initWithGeometryProviderModel:underlyingProviderModel
                                              randomState:randomState count:count distance:distance
                                              angle:angle scale:scale];
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNGeometryProvider> provider = [model provider];
      [provider valuesFromSamples:samples end:NO];
      DVNScatteredGeometryProviderModel *currentModel = [provider currentModel];

      expect(model.geometryProviderModel).toNot.equal(currentModel.geometryProviderModel);
      expect(model.randomState).toNot.equal(currentModel.randomState);
      expect(model.count == currentModel.count).to.beTruthy();
      expect(model.distance == currentModel.distance).to.beTruthy();
      expect(model.angle == currentModel.angle).to.beTruthy();
      expect(model.scale == currentModel.scale).to.beTruthy();
    });
  });

  context(@"non-deterministic", ^{
    context(@"bounds", ^{
      __block std::vector<lt::Quad> quads;
      __block std::vector<lt::Quad> underlyingQuads;
      __block std::vector<NSUInteger> indices;

      beforeEach(^{
        dvn::GeometryValues values = [[model provider] valuesFromSamples:samples end:NO];
        dvn::GeometryValues underlyingValues =
            [[underlyingProviderModel provider] valuesFromSamples:samples end:NO];
        quads = values.quads();
        underlyingQuads = underlyingValues.quads();
        indices = values.indices();
      });

      it(@"should provide quads with bounded centers", ^{
        for (NSUInteger i = 0; i < quads.size(); ++i) {
          CGFloat length = LTVector2(quads[i].center() -
                                     underlyingQuads[indices[i]].center()).length();
          expect(distance.contains(length)).to.beTruthy();
        }
      });

      it(@"should provide quads with bounded orientation", ^{
        for (NSUInteger i = 0; i < quads.size(); ++i) {
          for (NSUInteger j = 0; j < quads[i].kNumQuadCorners; ++j) {
            LTVector2 originalCornerVector = LTVector2(underlyingQuads[indices[i]].corners()[j] -
                                                       underlyingQuads[indices[i]].center());
            LTVector2 cornerVector = LTVector2(quads[i].corners()[j] - quads[i].center());
            expect(angle.contains(originalCornerVector.angle(cornerVector))).to.beTruthy();
          }
        }
      });

      it(@"should provide quads with bounded scale", ^{
        for (NSUInteger i = 0; i < quads.size(); ++i) {
          for (NSUInteger j = 0; j < quads[i].kNumQuadCorners; ++j) {
            LTVector2 originalCornerVector = LTVector2(underlyingQuads[indices[i]].corners()[j] -
                                                       underlyingQuads[indices[i]].center());
            LTVector2 cornerVector = LTVector2(quads[i].corners()[j] - quads[i].center());
            expect(scale.contains(cornerVector.length() /
                                  originalCornerVector.length())).to.beTruthy();
          }
        }
      });
    });
  });
});

SpecEnd
