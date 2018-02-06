// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModel.h"

#import "DVNBrushModelVersion.h"

SpecBegin(DVNBrushModel)

static NSDictionary * const kDictionary = @{
  @"version": @"1",
  @"scaleRange": @"[7, 9)",
  @"scale": @8,
};

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    DVNBrushModel *model = [[DVNBrushModel alloc] init];
    expect(model.version).to.equal($(DVNBrushModelVersionV1));
    expect(model.scale).to.equal(1);
    expect(model.scaleRange == lt::Interval<CGFloat>({0, CGFLOAT_MAX}, lt::Interval<CGFloat>::Open,
                                                     lt::Interval<CGFloat>::Closed)).to.beTruthy();
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
      expect(model.scaleRange == lt::Interval<CGFloat>({7, 9}, lt::Interval<CGFloat>::Closed,
                                                       lt::Interval<CGFloat>::Open)).to.beTruthy();
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

context(@"image URL property keys", ^{
  it(@"should return the correct property keys", ^{
    expect([DVNBrushModel imageURLPropertyKeys]).to.equal(@[]);
  });
});

SpecEnd
