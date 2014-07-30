// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTransformers.h"

LTEnumMake(NSUInteger, LTTransformEnum,
           LTTransformEnumA
);

static id LTForwardReverseTransform(NSValueTransformer *transformer, id object) {
  id forward = [transformer reverseTransformedValue:object];
  return [transformer transformedValue:forward];
}

SpecBegin(LTTransformers)

context(@"transformers for type encoding", ^{
  it(@"should return transformers for LTVectors", ^{
    expect([LTTransformers transformerForTypeEncoding:@(@encode(LTVector2))]).toNot.beNil();
    expect([LTTransformers transformerForTypeEncoding:@(@encode(LTVector3))]).toNot.beNil();
    expect([LTTransformers transformerForTypeEncoding:@(@encode(LTVector4))]).toNot.beNil();
  });

  it(@"should forward and reverse transformer for LTVector2", ^{
    LTVector2 vector(1, 2);
    NSValueTransformer *transformer =
        [LTTransformers transformerForTypeEncoding:@(@encode(LTVector2))];
    expect(LTForwardReverseTransform(transformer, $(vector))).to.equal($(vector));
  });

  it(@"should forward and reverse transformer for LTVector2", ^{
    LTVector3 vector(1, 2, 3);
    NSValueTransformer *transformer =
        [LTTransformers transformerForTypeEncoding:@(@encode(LTVector3))];
    expect(LTForwardReverseTransform(transformer, $(vector))).to.equal($(vector));
  });

  it(@"should forward and reverse transformer for LTVector2", ^{
    LTVector4 vector(1, 2, 3, 4);
    NSValueTransformer *transformer =
        [LTTransformers transformerForTypeEncoding:@(@encode(LTVector4))];
    expect(LTForwardReverseTransform(transformer, $(vector))).to.equal($(vector));
  });
});

context(@"transformers for class", ^{
  it(@"should return transformers for LTEnum", ^{
    expect([LTTransformers transformerForClass:[LTTransformEnum class]]).toNot.beNil();
  });

  it(@"should forward and reverse transformer for LTEnum", ^{
    LTTransformEnum *value = $(LTTransformEnumA);
    NSValueTransformer *transformer =
        [LTTransformers transformerForClass:[LTTransformEnum class]];
    expect(LTForwardReverseTransform(transformer, value)).to.equal(value);
  });
});

SpecEnd
