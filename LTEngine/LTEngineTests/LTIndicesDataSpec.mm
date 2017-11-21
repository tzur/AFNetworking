// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ofir Gluzman.

#import "LTIndicesData.h"

#import <LTKitTestUtils/LTEqualityExamples.h>

SpecBegin(LTIndicesData)

context(@"byte indices", ^{
  __block std::vector<GLubyte> indices;
  __block LTIndicesData *indicesData;

  beforeEach(^{
    indices = std::vector<GLubyte>{0, 1, 2};
    indicesData = [LTIndicesData dataWithByteIndices:indices];
  });

  afterEach(^{
    indicesData = nil;
  });

  it(@"should have a correct type", ^{
    expect(indicesData.type).to.equal(LTIndicesBufferTypeByte);
  });

  it(@"should have a correct count", ^{
    expect(indicesData.count).to.equal(3);
  });

  it(@"should hava correct data", ^{
    NSData *expectedData = [NSData dataWithBytes:&indices[0]
                                          length:indices.size() * sizeof(GLubyte)];
    expect(indicesData.data).to.equal(expectedData);
  });
});

context(@"short indices", ^{
  __block std::vector<GLushort> indices;
  __block LTIndicesData *indicesData;

  beforeEach(^{
    indices = std::vector<GLushort>{0, 1, 2};
    indicesData = [LTIndicesData dataWithShortIndices:indices];
  });

  afterEach(^{
    indicesData = nil;
  });

  it(@"should have a correct type", ^{
    expect(indicesData.type).to.equal(LTIndicesBufferTypeShort);
  });

  it(@"should have a correct count", ^{
    expect(indicesData.count).to.equal(3);
  });

  it(@"should hava correct data", ^{
    NSData *expectedData = [NSData dataWithBytes:&indices[0]
                                          length:indices.size() * sizeof(GLushort)];
    expect(indicesData.data).to.equal(expectedData);
  });
});

context(@"integer indices", ^{
  __block std::vector<GLuint> indices;
  __block LTIndicesData *indicesData;

  beforeEach(^{
    indices = std::vector<GLuint>{0, 1, 2};
    indicesData = [LTIndicesData dataWithIntegerIndices:indices];
  });

  afterEach(^{
    indicesData = nil;
  });

  it(@"should have a correct type", ^{
    expect(indicesData.type).to.equal(LTIndicesBufferTypeInteger);
  });

  it(@"should have a correct count", ^{
    expect(indicesData.count).to.equal(3);
  });

  it(@"should hava correct data", ^{
    NSData *expectedData = [NSData dataWithBytes:&indices[0]
                                          length:indices.size() * sizeof(GLuint)];
    expect(indicesData.data).to.equal(expectedData);
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  return @{
    kLTEqualityExamplesObject: [LTIndicesData dataWithIntegerIndices:{0, 1, 2}],
    kLTEqualityExamplesEqualObject: [LTIndicesData dataWithIntegerIndices:{0, 1, 2}],
    kLTEqualityExamplesDifferentObjects: @[[LTIndicesData dataWithIntegerIndices:{0, 1, 2, 3}],
                                           [LTIndicesData dataWithByteIndices:{0, 1, 2}],
                                           [LTIndicesData dataWithShortIndices:{0, 1, 2}]]
  };
});

SpecEnd
