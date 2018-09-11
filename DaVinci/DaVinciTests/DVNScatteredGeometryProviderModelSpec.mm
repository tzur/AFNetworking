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

@interface DVNScatteredGeometryProviderModelTestModel : NSObject <DVNGeometryProviderModel>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCount:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) NSUInteger count;

@end

@interface DVNScatteredGeometryProviderModelTestProvider : NSObject <DVNGeometryProvider>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithCount:(NSUInteger)count NS_DESIGNATED_INITIALIZER;

@property (readonly, nonatomic) NSUInteger count;

@end

@implementation DVNScatteredGeometryProviderModelTestProvider

- (instancetype)initWithCount:(NSUInteger)count {
  if (self = [super init]) {
    _count = count;
  }
  return self;
}

- (dvn::GeometryValues)valuesFromSamples:(id<LTSampleValues>)samples end:(__unused BOOL)end {
  std::vector<lt::Quad> quads = {lt::Quad()};
  std::vector<NSUInteger> indices = {0};
  for (NSUInteger i = 1; i < self.count; ++i) {
    samples = [samples concatenatedWithSampleValues:samples];
    quads.push_back(lt::Quad());
    indices.push_back(i);
  }
  return !self.count ? dvn::GeometryValues() : dvn::GeometryValues(quads, indices, samples);
}

- (id<DVNGeometryProviderModel>)currentModel {
  return [[DVNScatteredGeometryProviderModelTestModel alloc] initWithCount:self.count];
}

@end

@implementation DVNScatteredGeometryProviderModelTestModel

- (instancetype)initWithCount:(NSUInteger)count {
  if (self = [super init]) {
    _count = count;
  }
  return self;
}

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (id<DVNGeometryProvider>)provider {
  return [[DVNScatteredGeometryProviderModelTestProvider alloc] initWithCount:self.count];
}

@end

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
__block CGFloat startTaperingFactor;
__block CGFloat endTaperingFactor;
__block CGFloat minimumTaperingScaleFactor;
__block DVNScatteredGeometryProviderModel *model;

beforeEach(^{
  underlyingProviderModel =
      [[DVNTestGeometryProviderModel alloc]
       initWithState:0 quads:{lt::Quad(CGRectMake(0, 1, 2, 3)), lt::Quad(CGRectMake(4, 5, 6, 7))}];
  randomState = [[LTRandom alloc] init].engineState;
  count = lt::Interval<NSUInteger>({300, 500});
  distance = lt::Interval<CGFloat>({1, 5});
  angle = lt::Interval<CGFloat>({M_PI_4, M_PI});
  scale = lt::Interval<CGFloat>({0.5, 1.5});
  lengthOfStartTapering = 7;
  lengthOfEndTapering = 8;
  startTaperingFactor = 0.5;
  endTaperingFactor = 0.6;
  minimumTaperingScaleFactor = 0.1;

  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[@"xKey", @"yKey"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];

  model = [[DVNScatteredGeometryProviderModel alloc]
           initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
           count:count distance:distance angle:angle scale:scale
           lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
           startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
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
    expect(model.startTaperingFactor).to.equal(1);
    expect(model.endTaperingFactor).to.equal(1);
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
    expect(model.startTaperingFactor).to.equal(startTaperingFactor);
    expect(model.endTaperingFactor).to.equal(endTaperingFactor);
    expect(model.minimumTaperingScaleFactor).to.equal(minimumTaperingScaleFactor);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNScatteredGeometryProviderModel *model =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale
       lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
       startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
       minimumTaperingScaleFactor:minimumTaperingScaleFactor];
  DVNScatteredGeometryProviderModel *equalModel =
      [[DVNScatteredGeometryProviderModel alloc]
       initWithGeometryProviderModel:underlyingProviderModel randomState:randomState count:count
       distance:distance angle:angle scale:scale
       lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
       startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
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
      expect(currentModel.startTaperingFactor).to.equal(model.startTaperingFactor);
      expect(currentModel.endTaperingFactor).to.equal(model.endTaperingFactor);
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
        distance = lt::Interval<CGFloat>({minimumTaperingScaleFactor * *distance.min(),
                                          *distance.max()});
        scale = lt::Interval<CGFloat>({minimumTaperingScaleFactor * *scale.min(), *scale.max()});
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

      context(@"special cases", ^{
        static const std::vector<lt::Quad> kQuads = {
          lt::Quad(CGRectMake(0, 0, 1, 1)),
          lt::Quad(CGRectMake(1, 1, 2, 2))
        };

        it(@"should provide quads with correctly bounded scale, when tapering lenghts overlap", ^{
          auto underlyingProviderModel = [[DVNTestGeometryProviderModel alloc]
                                          initWithState:0 quads:kQuads];
          auto model = [[DVNScatteredGeometryProviderModel alloc]
                        initWithGeometryProviderModel:underlyingProviderModel
                        randomState:randomState
                        count:lt::Interval<NSUInteger>(2) distance:lt::Interval<CGFloat>(0)
                        angle:lt::Interval<CGFloat>(0) scale:lt::Interval<CGFloat>(1)
                        lengthOfStartTapering:10 lengthOfEndTapering:10 startTaperingFactor:1
                        endTaperingFactor:1 minimumTaperingScaleFactor:0.1];
          dvn::GeometryValues values = [[model provider] valuesFromSamples:samples end:YES];
          auto quads = values.quads();

          CGFloat maxDimension = 0;
          for (NSUInteger i = 0; i < quads.size(); ++i) {
            maxDimension = std::max(maxDimension, std::max(quads[i].boundingRect().size));
          }
          expect(maxDimension).to.beGreaterThan(0.15);
        });

        it(@"should provide quads with correctly bounded scale, when end is YES", ^{
          auto underlyingProviderModel = [[DVNTestGeometryProviderModel alloc]
                                          initWithState:0 quads:kQuads];
          auto model = [[DVNScatteredGeometryProviderModel alloc]
                        initWithGeometryProviderModel:underlyingProviderModel
                        randomState:randomState
                        count:lt::Interval<NSUInteger>(2) distance:lt::Interval<CGFloat>(0)
                        angle:lt::Interval<CGFloat>(0) scale:lt::Interval<CGFloat>(1)
                        lengthOfStartTapering:0.5 lengthOfEndTapering:0 startTaperingFactor:1
                        endTaperingFactor:1 minimumTaperingScaleFactor:0.1];
          dvn::GeometryValues values = [[model provider] valuesFromSamples:samples end:YES];
          auto quads = values.quads();

          CGFloat maxDimension = 0;
          for (NSUInteger i = 0; i < quads.size(); ++i) {
            maxDimension = std::max(maxDimension, std::max(quads[i].boundingRect().size));
          }
          expect(maxDimension).to.beGreaterThan(0.15);
        });
      });
    });
  });

  context(@"geometry values", ^{
    it(@"should provide no samples if underlying provider returns no samples", ^{
      DVNScatteredGeometryProviderModelTestModel *underlyingProviderModel =
          [[DVNScatteredGeometryProviderModelTestModel alloc] initWithCount:0];
      model = [[DVNScatteredGeometryProviderModel alloc]
               initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
               count:count distance:distance angle:angle scale:scale
               lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
               startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
               minimumTaperingScaleFactor:minimumTaperingScaleFactor];
      id<DVNGeometryProvider> provider = [model provider];

      dvn::GeometryValues values = [provider valuesFromSamples:samples end:NO];

      expect(values).to.equal(dvn::GeometryValues());
    });

    it(@"should provide correct samples if underlying provider returns different samples", ^{
      DVNScatteredGeometryProviderModelTestModel *underlyingProviderModel =
          [[DVNScatteredGeometryProviderModelTestModel alloc] initWithCount:2];
      model = [[DVNScatteredGeometryProviderModel alloc]
               initWithGeometryProviderModel:underlyingProviderModel randomState:randomState
               count:count distance:distance angle:angle scale:scale
               lengthOfStartTapering:lengthOfStartTapering lengthOfEndTapering:lengthOfEndTapering
               startTaperingFactor:startTaperingFactor endTaperingFactor:endTaperingFactor
               minimumTaperingScaleFactor:minimumTaperingScaleFactor];
      id<DVNGeometryProvider> provider = [model provider];

      dvn::GeometryValues values = [provider valuesFromSamples:samples end:NO];

      LTSampleValues *expectedSampleValues = [samples concatenatedWithSampleValues:samples];
      expect(values.samples()).to.equal(expectedSampleValues);
    });
  });
});

SpecEnd
