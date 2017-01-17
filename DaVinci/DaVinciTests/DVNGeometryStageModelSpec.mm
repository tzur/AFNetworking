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
  it(@"should return DVNScatteredGeometryProviderModel geometry model", ^{
    id<DVNGeometryProviderModel> geometryModel = [model geometryProviderModel];
    expect(geometryModel).to.beKindOf([DVNScatteredGeometryProviderModel class]);
  });
  
  it(@"should return correctly initialized scattered geometry model", ^{
    DVNScatteredGeometryProviderModel *geometryModel = [model geometryProviderModel];
    expect(geometryModel.geometryProviderModel).to.beKindOf([DVNSquareProviderModel class]);
    expect(((DVNSquareProviderModel *)geometryModel.geometryProviderModel).edgeLength)
        .to.equal(model.diameter);
    expect(geometryModel.count == lt::Interval<NSUInteger>({model.minCount,
        model.maxCount}, lt::Interval<NSUInteger>::EndpointInclusion::Closed)).to.beTruthy();
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
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinDiameter): @1,
      @instanceKeypath(DVNScatteredGeometryStageModel, diameter): @2,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultDiameter): @3,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxDiameter): @4,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMinCount): @5,
      @instanceKeypath(DVNScatteredGeometryStageModel, minCount): @6,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMinCount): @7,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMinCount): @8,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMaxCount): @9,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxCount): @10,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMaxCount): @11,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMaxCount): @12,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMinDistance): @13,
      @instanceKeypath(DVNScatteredGeometryStageModel, minDistance): @14,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMinDistance): @15,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMinDistance): @16,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMaxDistance): @17,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxDistance): @18,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMaxDistance): @19,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMaxDistance): @20,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMinAngle): @((CGFloat)0.1),
      @instanceKeypath(DVNScatteredGeometryStageModel, minAngle): @((CGFloat)0.2),
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMinAngle): @((CGFloat)0.3),
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMinAngle): @((CGFloat)0.4),
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMaxAngle): @((CGFloat)0.5),
      @instanceKeypath(DVNScatteredGeometryStageModel, maxAngle): @((CGFloat)0.6),
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMaxAngle): @((CGFloat)0.7),
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMaxAngle): @((CGFloat)0.8),
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMinScale): @21,
      @instanceKeypath(DVNScatteredGeometryStageModel, minScale): @22,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMinScale): @23,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMinScale): @24,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMinMaxScale): @25,
      @instanceKeypath(DVNScatteredGeometryStageModel, maxScale): @26,
      @instanceKeypath(DVNScatteredGeometryStageModel, defaultMaxScale): @27,
      @instanceKeypath(DVNScatteredGeometryStageModel, softMaxMaxScale): @28
    };
    model = [MTLJSONAdapter modelOfClass:[DVNScatteredGeometryStageModel class]
                      fromJSONDictionary:dictionary error:&error];
  });
  
  context(@"deserialization", ^{
    it(@"should deserialize without errors", ^{
      expect(error).to.beNil();
    });
    
    it(@"should deserialize correctly", ^{
      expect(model.softMinDiameter).to.equal(1);
      expect(model.diameter).to.equal(2);
      expect(model.defaultDiameter).to.equal(3);
      expect(model.softMaxDiameter).to.equal(4);
      expect(model.softMinMinCount).to.equal(5);
      expect(model.minCount).to.equal(6);
      expect(model.defaultMinCount).to.equal(7);
      expect(model.softMaxMinCount).to.equal(8);
      expect(model.softMinMaxCount).to.equal(9);
      expect(model.maxCount).to.equal(10);
      expect(model.defaultMaxCount).to.equal(11);
      expect(model.softMaxMaxCount).to.equal(12);
      expect(model.softMinMinDistance).to.equal(13);
      expect(model.minDistance).to.equal(14);
      expect(model.defaultMinDistance).to.equal(15);
      expect(model.softMaxMinDistance).to.equal(16);
      expect(model.softMinMaxDistance).to.equal(17);
      expect(model.maxDistance).to.equal(18);
      expect(model.defaultMaxDistance).to.equal(19);
      expect(model.softMaxMaxDistance).to.equal(20);
      expect(model.softMinMinAngle).to.equal(0.1);
      expect(model.minAngle).to.equal(0.2);
      expect(model.defaultMinAngle).to.equal(0.3);
      expect(model.softMaxMinAngle).to.equal(0.4);
      expect(model.softMinMaxAngle).to.equal(0.5);
      expect(model.maxAngle).to.equal(0.6);
      expect(model.defaultMaxAngle).to.equal(0.7);
      expect(model.softMaxMaxAngle).to.equal(0.8);
      expect(model.softMinMinScale).to.equal(21);
      expect(model.minScale).to.equal(22);
      expect(model.defaultMinScale).to.equal(23);
      expect(model.softMaxMinScale).to.equal(24);
      expect(model.softMinMaxScale).to.equal(25);
      expect(model.maxScale).to.equal(26);
      expect(model.defaultMaxScale).to.equal(27);
      expect(model.softMaxMaxScale).to.equal(28);
    });
  });
  
  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(dictionary);
    });
  });
});

SpecEnd
