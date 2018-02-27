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
__block CGFloat lengthOfStartTapering;
__block CGFloat lengthOfEndTapering;
__block CGFloat taperingExponent;
__block CGFloat minimumTaperingScaleFactor;
__block DVNScatteredGeometryProviderModel *model;

beforeEach(^{
  underlyingProviderModel = [[DVNTestGeometryProviderModel alloc] initWithState:0];
  randomState = [[LTRandom alloc] init].engineState;
  count = lt::Interval<NSUInteger>({300, 500});
  distance = lt::Interval<CGFloat>({1, 5});
  angle = lt::Interval<CGFloat>({M_PI_4, M_PI});
  scale = lt::Interval<CGFloat>({0.5, 1.5});
  lengthOfStartTapering = 7;
  lengthOfEndTapering = 8;
  taperingExponent = 0.5;
  minimumTaperingScaleFactor = 0.1;

  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[@"xKey", @"yKey"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];

  model = [[DVNScatteredGeometryProviderModel alloc]
           initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
           count:count distance:distance angle:angle scale:scale
           lengthOfStartTapering:lengthOfStartTapering
           lengthOfEndTapering:lengthOfEndTapering taperingExponent:taperingExponent
           minimumTaperingScaleFactor:minimumTaperingScaleFactor];
});

afterEach(^{
  samples = nil;
  model = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    model = [[DVNScatteredGeometryProviderModel alloc]
             initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
             count:count distance:distance angle:angle scale:scale];
    expect(model).toNot.beNil();
    expect(model.geometryProviderModel).to.equal(underlyingProviderModel);
    expect(model.randomState).to.equal(randomState);
    expect(model.count == count).to.beTruthy();
    expect(model.distance == distance).to.beTruthy();
    expect(model.angle == angle).to.beTruthy();
    expect(model.scale == scale).to.beTruthy();
    expect(model.lengthOfStartTapering).to.equal(0);
    expect(model.lengthOfEndTapering).to.equal(0);
    expect(model.taperingExponent).to.equal(1);
    expect(model.minimumTaperingScaleFactor).to.equal(1);
  });

  it(@"should initialize correctly with angle range values smaller than 4 PI", ^{
    angle = lt::Interval<CGFloat>({M_PI_4, 3 * M_PI});
    model = [[DVNScatteredGeometryProviderModel alloc]
             initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
             count:count distance:distance angle:angle scale:scale];
    expect(model.angle == angle).to.beTruthy();
  });

  it(@"should initialize correctly with tapering parameters", ^{
    expect(model).toNot.beNil();
    expect(model.geometryProviderModel).to.equal(underlyingProviderModel);
    expect(model.randomState).to.equal(randomState);
    expect(model.count == count).to.beTruthy();
    expect(model.distance == distance).to.beTruthy();
    expect(model.angle == angle).to.beTruthy();
    expect(model.scale == scale).to.beTruthy();
    expect(model.lengthOfStartTapering).to.equal(lengthOfStartTapering);
    expect(model.lengthOfEndTapering).to.equal(lengthOfEndTapering);
    expect(model.taperingExponent).to.equal(taperingExponent);
    expect(model.minimumTaperingScaleFactor).to.equal(minimumTaperingScaleFactor);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNScatteredGeometryProviderModel *model =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale lengthOfStartTapering:lengthOfStartTapering
       lengthOfEndTapering:lengthOfEndTapering taperingExponent:taperingExponent
       minimumTaperingScaleFactor:minimumTaperingScaleFactor];
  DVNScatteredGeometryProviderModel *equalModel =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale lengthOfStartTapering:lengthOfStartTapering
       lengthOfEndTapering:lengthOfEndTapering taperingExponent:taperingExponent
       minimumTaperingScaleFactor:minimumTaperingScaleFactor];
  DVNScatteredGeometryProviderModel *differentModel =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale];
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

      expect(currentModel.geometryProviderModel).toNot.equal(model.geometryProviderModel);
      expect(currentModel.randomState).toNot.equal(model.randomState);
      expect(model.count == currentModel.count).to.beTruthy();
      expect(model.distance == currentModel.distance).to.beTruthy();
      expect(model.angle == currentModel.angle).to.beTruthy();
      expect(model.scale == currentModel.scale).to.beTruthy();
      expect(currentModel.lengthOfStartTapering).to.equal(model.lengthOfStartTapering);
      expect(currentModel.lengthOfEndTapering).to.equal(model.lengthOfEndTapering);
      expect(currentModel.taperingExponent).to.equal(model.taperingExponent);
      expect(currentModel.minimumTaperingScaleFactor).to.equal(model.minimumTaperingScaleFactor);
    });
  });

  context(@"non-deterministic", ^{
    context(@"bounds without tapering", ^{
      __block std::vector<lt::Quad> quads;
      __block std::vector<lt::Quad> underlyingQuads;
      __block std::vector<NSUInteger> indices;

      beforeEach(^{
        model = [[DVNScatteredGeometryProviderModel alloc]
                 initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
                 count:count distance:distance angle:angle scale:scale];
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

    context(@"bounds with tapering", ^{
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
        distance = lt::Interval<CGFloat>({minimumTaperingScaleFactor * distance.inf(),
                                          distance.sup()});
        scale = lt::Interval<CGFloat>({minimumTaperingScaleFactor * scale.inf(), scale.sup()});
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
