// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNScatteredGeometryStageModel.h"

#import <LTKit/LTRandom.h>

#import "DVNScatteredGeometryProviderModel.h"
#import "DVNSquareProvider.h"

SpecBegin(DVNScatteredGeometryStageModel)

__block DVNScatteredGeometryStageModel *model;

beforeEach(^{
  model = [[DVNScatteredGeometryStageModel alloc] init];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });
});

context(@"DVNGeometryStageModel", ^{
  beforeEach(^{
    model.diameter = 1;
    model.maxCount = 5;
    model.minDistance = 3;
    model.maxDistance = 10;
    model.minAngle = M_PI_4;
    model.maxAngle = M_PI;
    model.minScale = 0.5;
    model.maxScale = 4;
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
    expect(geometryModel.maximumCount).to.equal(model.maxCount);
    expect(geometryModel.distance == lt::Interval<CGFloat>({model.minDistance,
        model.maxDistance}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
    expect(geometryModel.angle == lt::Interval<CGFloat>({model.minAngle,
        model.maxAngle}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
    expect(geometryModel.scale == lt::Interval<CGFloat>({model.minScale,
        model.maxScale}, lt::Interval<CGFloat>::EndpointInclusion::Closed)).to.beTruthy();
  });
});

context(@"de/serialization", ^{
  __block NSDictionary *dictionary;
  __block NSError *error;
  
  beforeEach(^{
    dictionary = @{
      @instanceKeypath(DVNScatteredGeometryStageModel, diameter): @0,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultDiameter): @1,
      @instanceKeypath(DVNScatteredGeometryStageModel, minDiameter): @2,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxDiameter): @3,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxCount): @4,
      @instanceKeypath(DVNScatteredGeometryStageModel, minDistance): @5,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxDistance): @6,
      @instanceKeypath(DVNScatteredGeometryStageModel, minAngle): @7,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxAngle): @8,
      @instanceKeypath(DVNScatteredGeometryStageModel, minScale): @9,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxScale): @10
    };
    model = [MTLJSONAdapter modelOfClass:[DVNScatteredGeometryStageModel class]
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
      expect(model.maxCount).to.equal(4);
      expect(model.minDistance).to.equal(5);
      expect(model.maxDistance).to.equal(6);
      expect(model.minAngle).to.equal(7);
      expect(model.maxAngle).to.equal(8);
      expect(model.minScale).to.equal(9);
      expect(model.maxScale).to.equal(10);
    });
  });
  
  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(dictionary);
    });
  });
});

SpecEnd
