// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNGeometryStageModel.h"

#import <LTKit/LTRandom.h>

#import "DVNScatteredGeometryProviderModel.h"
#import "DVNSquareProvider.h"

SpecBegin(DVNGeometryStageModel)

__block DVNGeometryStageModel *model;

beforeEach(^{
  model = [[DVNGeometryStageModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

context(@"DVNGeometryStageModel", ^{
  beforeEach(^{
    model.diameter = 1;
    model.maxScatterCount = 5;
    model.minScatterDistance = 3;
    model.maxScatterDistance = 10;
    model.minScatterAngle = M_PI_4;
    model.maxScatterAngle = M_PI;
    model.minScatterScale = 0.5;
    model.maxScatterScale = 4;
  });
  
  it(@"should return DVNScatteredGeometryProviderModel geometry model", ^{
    id<DVNGeometryProviderModel> geometryModel = [model geometryProviderModel];
    expect(geometryModel).to.beKindOf([DVNScatteredGeometryProviderModel class]);
  });
  
  it(@"should return correctly initialized scattered geometry model", ^{
    DVNScatteredGeometryProviderModel *geometryModel = [model geometryProviderModel];
    expect(geometryModel.geometryProviderModel).to.beKindOf([DVNSquareProviderModel class]);
    expect(((DVNSquareProviderModel *)geometryModel.geometryProviderModel).edgeLength)
        .to.equal(model.diameter);
    expect(geometryModel.maximumCount).to.equal(model.maxScatterCount);
    expect(geometryModel.distance == lt::Interval<CGFloat>({model.minScatterDistance,
        model.maxScatterDistance}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
    expect(geometryModel.angle == lt::Interval<CGFloat>({model.minScatterAngle,
        model.maxScatterAngle}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
    expect(geometryModel.scale == lt::Interval<CGFloat>({model.minScatterScale,
        model.maxScatterScale}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
  });
});

context(@"de/serialization", ^{
  __block NSDictionary *dictionary;
  __block NSError *error;
  
  beforeEach(^{
    dictionary = @{
      @instanceKeypath(DVNGeometryStageModel, diameter): @0,
      @instanceKeypath(DVNGeometryStageModel, defaultDiameter): @1,
      @instanceKeypath(DVNGeometryStageModel, minDiameter): @2,
      @instanceKeypath(DVNGeometryStageModel, maxDiameter): @3,
      @instanceKeypath(DVNGeometryStageModel, maxScatterCount): @4,
      @instanceKeypath(DVNGeometryStageModel, minScatterDistance): @5,
      @instanceKeypath(DVNGeometryStageModel, maxScatterDistance): @6,
      @instanceKeypath(DVNGeometryStageModel, minScatterAngle): @7,
      @instanceKeypath(DVNGeometryStageModel, maxScatterAngle): @8,
      @instanceKeypath(DVNGeometryStageModel, minScatterScale): @9,
      @instanceKeypath(DVNGeometryStageModel, maxScatterScale): @10
    };
    model = [MTLJSONAdapter modelOfClass:[DVNGeometryStageModel class]
                      fromJSONDictionary:dictionary error:&error];
  });
  
  context(@"deserialization", ^{
    it(@"should deserialize without errors", ^{
      expect(error).to.beNil();
    });
    
    it(@"should deserialize correctly", ^{
      expect(model.diameter).to.equal(0);
      expect(model.defaultDiameter).to.equal(1);
      expect(model.minDiameter).to.equal(2);
      expect(model.maxDiameter).to.equal(3);
      expect(model.maxScatterCount).to.equal(4);
      expect(model.minScatterDistance).to.equal(5);
      expect(model.maxScatterDistance).to.equal(6);
      expect(model.minScatterAngle).to.equal(7);
      expect(model.maxScatterAngle).to.equal(8);
      expect(model.minScatterScale).to.equal(9);
      expect(model.maxScatterScale).to.equal(10);
    });
  });
  
  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(dictionary);
    });
  });
});

SpecEnd
