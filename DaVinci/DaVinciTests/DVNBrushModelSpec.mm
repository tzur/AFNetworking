// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

SpecBegin(DVNBrushModel)

static NSDictionary * const kDictionary = @{
  @instanceKeypath(DVNBrushModel, brushModelVersion): @1,
  @instanceKeypath(DVNBrushModel, scale): @7,
  @instanceKeypath(DVNBrushModel, minScale): @8,
  @instanceKeypath(DVNBrushModel, maxScale): @9
};

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNBrushModel *model = [[DVNBrushModel alloc] init];
    expect(model.brushModelVersion).to.equal(1);
    expect(model.scale).to.equal(1);
    expect(model.minScale).to.equal(0);
    expect(model.maxScale).to.equal(CGFLOAT_MAX);
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
      expect(model.brushModelVersion).to.equal(1);
      expect(model.scale).to.equal(7);
      expect(model.minScale).to.equal(8);
      expect(model.maxScale).to.equal(9);
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

SpecEnd
