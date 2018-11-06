// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNGeometryValues.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>

SpecBegin(DVNGeometryValues)

static NSOrderedSet<NSString *> * const kKeys = [NSOrderedSet orderedSetWithObject:@"key"];

__block std::vector<lt::Quad> quads;
__block std::vector<NSUInteger> indices;
__block id<LTSampleValues> samples;

beforeEach(^{
  quads = {lt::Quad(CGRectZero)};
  indices = {0};
  std::vector<CGFloat> sampledParametricValues = {0};
  cv::Mat1g values(1, 1, 7);
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:kKeys valuesPerKey:values];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:sampledParametricValues
                                                            mapping:mapping];
});

context(@"initialization", ^{
  it(@"should initialize correctly without values", ^{
    dvn::GeometryValues geometryValues = dvn::GeometryValues();

    LTSampleValues *expectedSampleValues =
        [[LTSampleValues alloc] initWithSampledParametricValues:{} mapping:nil];
    expect(geometryValues.quads().size()).to.equal(0);
    expect(geometryValues.indices().size()).to.equal(0);
    expect(geometryValues.samples()).to.equal(expectedSampleValues);
  });

  it(@"should initialize correctly", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);

    expect(geometryValues.quads() == quads).to.beTruthy();
    expect(geometryValues.indices() == indices).to.beTruthy();
    expect(geometryValues.samples()).to.equal(samples);
  });

  it(@"should initialize with a copy of the provided quads", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    quads.push_back(lt::Quad());
    expect(quads.size()).to.equal(2);
    expect(geometryValues.quads().size()).to.equal(1);
  });

  it(@"should initialize with a copy of the provided indices", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    indices.push_back(0);
    expect(indices.size()).to.equal(2);
    expect(geometryValues.indices().size()).to.equal(1);
  });

  context(@"invalid parameters", ^{
    it(@"should raise when attempting to initialize with mismatching size of indices", ^{
      expect(^{
        dvn::GeometryValues geometryValues(quads, {}, samples);
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize without samples", ^{
      expect(^{
        dvn::GeometryValues geometryValues({}, {}, nil);
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

context(@"move constructor", ^{
  it(@"should correctly use the move constructor", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    dvn::GeometryValues otherGeometryValues = std::move(geometryValues);

    expect(geometryValues.quads().size()).to.equal(0);
    expect(geometryValues.indices().size()).to.equal(0);
    expect(geometryValues.samples()).to.beNil();
    expect(otherGeometryValues.quads() == quads).to.beTruthy();
    expect(otherGeometryValues.indices() == indices).to.beTruthy();
    expect(otherGeometryValues.samples()).to.equal(samples);
  });

  it(@"should provide a reference to the quads", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    const std::vector<lt::Quad> &reference = geometryValues.quads();
    expect(reference.size()).to.equal(1);
    std::vector<lt::Quad> &mutableQuads = const_cast<std::vector<lt::Quad> &>(reference);

    mutableQuads.push_back(lt::Quad());

    expect(reference.size()).to.equal(2);
  });

  it(@"should provide a reference to the indices", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    const std::vector<NSUInteger> &reference = geometryValues.indices();
    expect(reference.size()).to.equal(1);
    std::vector<NSUInteger> &mutableQuads = const_cast<std::vector<NSUInteger> &>(reference);

    mutableQuads.push_back(1);

    expect(reference.size()).to.equal(2);
  });
});

context(@"equality", ^{
  it(@"should correctly compare two equal geometry values", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    dvn::GeometryValues equalGeometryValues(quads, indices, samples);;
    expect(geometryValues == equalGeometryValues).to.beTruthy();
    expect(geometryValues != equalGeometryValues).to.beFalsy();
  });

  it(@"should correctly compare two different geometry values", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    dvn::GeometryValues differentGeometryValues(quads, {2}, samples);;
    expect(geometryValues != differentGeometryValues).to.beTruthy();
    expect(geometryValues == differentGeometryValues).to.beFalsy();
  });
});

context(@"hash", ^{
  it(@"should return the same hash value for equal objects", ^{
    dvn::GeometryValues geometryValues(quads, indices, samples);
    dvn::GeometryValues equalGeometryValues(quads, indices, samples);
    expect(std::hash<dvn::GeometryValues>()(geometryValues))
        .to.equal(std::hash<dvn::GeometryValues>()(equalGeometryValues));
  });
});

SpecEnd
