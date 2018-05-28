// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

#import <LTEngine/LTTexture.h>

#import "DVNBrushModelVersion.h"

SpecBegin(DVNBrushModel)

static NSDictionary * const kDictionary = @{
  @"version": @"1",
  @"scaleRange": @"[7, 9)",
  @"scale": @8,
  @"randomInitialSeed": @YES,
  @"initialSeed": @7
};

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNBrushModel *model = [[DVNBrushModel alloc] init];
    expect(model.version).to.equal($(DVNBrushModelVersionV1));
    expect(model.scale).to.equal(1);
    expect(model.scaleRange == lt::Interval<CGFloat>::oc({0, CGFLOAT_MAX})).to.beTruthy();
    expect(model.randomInitialSeed).to.beFalsy();
    expect(model.initialSeed).to.equal(0);
  });

  context(@"deserialization", ^{
    __block DVNBrushModel *model;
    __block NSError *error;

    beforeEach(^{
      model = [MTLJSONAdapter modelOfClass:[DVNBrushModel class] fromJSONDictionary:kDictionary
                                     error:&error];
    });

    it(@"should deserialize without an error", ^{
      expect(model).toNot.beNil();
      expect(error).to.beNil();
    });

    it(@"should deserialize with correct values", ^{
      expect(model.version).to.equal($(DVNBrushModelVersionV1));
      expect(model.scale).to.equal(8);
      expect(model.scaleRange == lt::Interval<CGFloat>::co({7, 9})).to.beTruthy();
      expect(model.randomInitialSeed).to.beTruthy();
      expect(model.initialSeed).to.equal(7);
    });
  });

  context(@"serialization", ^{
    it(@"should serialize correctly", ^{
      DVNBrushModel *model = [MTLJSONAdapter modelOfClass:[DVNBrushModel class]
                                       fromJSONDictionary:kDictionary error:nil];
      expect([MTLJSONAdapter JSONDictionaryFromModel:model]).to.equal(kDictionary);
    });
  });
});

context(@"copy constructors", ^{
  __block DVNBrushModel *model;

  beforeEach(^{
    model = [MTLJSONAdapter modelOfClass:[DVNBrushModel class] fromJSONDictionary:kDictionary
                                   error:nil];
  });

  context(@"scale", ^{
    it(@"should return a copy scaled by a given scale", ^{
      DVNBrushModel *scaledModel = [model scaledBy:2];
      expect(scaledModel.scale).to.equal(16);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::co({14, 18})).to.beTruthy();
    });

    it(@"should return a copy with a given scale", ^{
      DVNBrushModel *scaledModel = [model copyWithScale:7.5];
      expect(scaledModel.scale).to.equal(7.5);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::co({7, 9})).to.beTruthy();
    });

    it(@"should return a copy with a given scale, clamped to the scale range", ^{
      DVNBrushModel *scaledModel = [model copyWithScale:1];
      expect(scaledModel.scale).to.equal(7);
      expect(scaledModel.scaleRange == lt::Interval<CGFloat>::co({7, 9})).to.beTruthy();
    });
  });

  context(@"random initial seed indication", ^{
    it(@"should return a copy with given random initial seed indication", ^{
      DVNBrushModel *modelCopy = [model copyWithRandomInitialSeed:!model.randomInitialSeed];
      expect(modelCopy.randomInitialSeed).to.equal(!model.randomInitialSeed);
    });
  });

  context(@"initial seed", ^{
    it(@"should return a copy with initial seed", ^{
      DVNBrushModel *modelCopy = [model copyWithInitialSeed:8];
      expect(modelCopy.initialSeed).to.equal(8);
      expect(modelCopy.initialSeed).toNot.equal(model.initialSeed);
    });
  });
});

context(@"texture mapping validation", ^{
  __block DVNBrushModel *model;

  beforeEach(^{
    model = [MTLJSONAdapter modelOfClass:[DVNBrushModel class] fromJSONDictionary:kDictionary
                                   error:nil];
  });

  it(@"should claim that texture mapping is valid if keys are subset of image URL property keys", ^{
    expect([model isValidTextureMapping:@{}]).to.beTruthy();
  });

  it(@"should claim that texture mapping is invalid if keys are not subset of property keys", ^{
    expect([model isValidTextureMapping:@{@"foo": OCMClassMock([LTTexture class])}]).to.beFalsy();
  });
});

context(@"image URL property keys", ^{
  it(@"should return the correct property keys", ^{
    expect([DVNBrushModel imageURLPropertyKeys]).to.equal(@[]);
  });
});

context(@"allowed ranges", ^{
  it(@"should return the allowed scale range", ^{
    expect([DVNBrushModel allowedScaleRange] ==
           lt::Interval<CGFloat>::oc({0, std::numeric_limits<CGFloat>::max()})).to.beTruthy();
  });
});

SpecEnd
