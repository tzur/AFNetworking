// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNDirectedRectProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProviderExamples.h"

SpecBegin(DVNDirectedRectProvider)

__block CGSize size;
__block NSOrderedSet<NSString *> *keys;
__block id<LTSampleValues> samples;

beforeEach(^{
  size = CGSizeMake(7, 8);
  keys = [NSOrderedSet orderedSetWithArray:@[@"xKey", @"yKey"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];
});

afterEach(^{
  samples = nil;
});

context(@"initialization", ^{
  it(@"should initialize with given edge length and default values", ^{
    DVNDirectedRectProviderModel *model = [[DVNDirectedRectProviderModel alloc] initWithSize:size];
    expect(model).toNot.beNil();
    expect(model.size).to.equal(size);
    expect(model.xCoordinateKey)
        .to.equal(@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation));
    expect(model.yCoordinateKey)
        .to.equal(@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation));
  });

  it(@"should initialize with given edge length and keys", ^{
    DVNDirectedRectProviderModel *model =
        [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                            yCoordinateKey:@"yKey"];
    expect(model).toNot.beNil();
    expect(model.size).to.equal(size);
    expect(model.xCoordinateKey).to.equal(@"xKey");
    expect(model.yCoordinateKey).to.equal(@"yKey");
  });

  context(@"invalid initialization attempts", ^{
    it(@"should raise when attempting to initialize with invalid size", ^{
      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:CGSizeMake(7, -1)];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:CGSizeMake(7, 0)];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:CGSizeMake(7, -1)
                                                xCoordinateKey:@"xKey" yCoordinateKey:@"yKey"];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:CGSizeMake(7, 0)
                                                xCoordinateKey:@"xKey" yCoordinateKey:@"yKey"];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with empty key", ^{
      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                                yCoordinateKey:@""];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with equal keys", ^{
      expect(^{
        DVNDirectedRectProviderModel * __unused model =
            [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"key"
                                                yCoordinateKey:@"key"];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  DVNDirectedRectProviderModel *model =
      [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                          yCoordinateKey:@"yKey"];
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples
  };
});

itShouldBehaveLike(kDVNDeterministicGeometryProviderExamples, ^{
  DVNDirectedRectProviderModel *model = [[DVNDirectedRectProviderModel alloc] initWithSize:size
                                                                            xCoordinateKey:@"xKey"
                                                                            yCoordinateKey:@"yKey"];

  CGPoint firstCenter = CGPointMake(1, 3);
  CGPoint secondCenter = CGPointMake(2, 4);
  CGFloat angle = LTVector2(secondCenter - firstCenter).angle(LTVector2(1, 0));

  NSArray<NSValue *> *expectedQuads = DVNConvertedBoxedQuadsFromQuads({
    lt::Quad(CGRectCenteredAt(firstCenter, size)).rotatedAroundPoint(-angle, firstCenter),
    lt::Quad(CGRectCenteredAt(secondCenter, size)).rotatedAroundPoint(-angle, secondCenter)
  });
  std::vector<NSUInteger> indices = {0, 1};
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples,
    kDVNGeometryProviderExamplesExpectedQuads: expectedQuads,
    kDVNGeometryProviderExamplesExpectedIndices: $(indices)
  };
});

context(@"single sample", ^{
  __block DVNDirectedRectProviderModel *model;

  beforeEach(^{
    model = [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                                yCoordinateKey:@"yKey"];

    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                               valuesPerKey:(cv::Mat1g(2, 1) << 1, 3)];
    samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0} mapping:mapping];
  });

  it(@"should provide the correct quad for single sample with end indication set to NO", ^{
    itShouldBehaveLike(kDVNDeterministicGeometryProviderExamples, ^{
      NSArray<NSValue *> *expectedQuads = DVNConvertedBoxedQuadsFromQuads({
        lt::Quad(CGRectCenteredAt(CGPointMake(1, 3), CGSizeMakeUniform(0)))
      });
      std::vector<NSUInteger> indices = {0};
      return @{
        kDVNGeometryProviderExamplesModel: model,
        kDVNGeometryProviderExamplesSamples: samples,
        kDVNGeometryProviderExamplesExpectedQuads: expectedQuads,
        kDVNGeometryProviderExamplesExpectedIndices: $(indices)
      };
    });
  });

  it(@"should provide the correct quad for single sample with end indication set to YES", ^{
    dvn::GeometryValues geometryValues = [[model provider] valuesFromSamples:samples end:YES];
    expect(geometryValues.quads().size()).to.equal(1);
    expect(geometryValues.quads().front() == lt::Quad(CGRectCenteredAt(CGPointMake(1, 3),
                                                                       size))).to.beTruthy();
  });
});

context(@"multiple consecutive samples", ^{
  __block id<DVNGeometryProvider> provider;
  __block id<LTSampleValues> additionalSamples;

  beforeEach(^{
    DVNDirectedRectProviderModel *model = [[DVNDirectedRectProviderModel alloc]
                                           initWithSize:size xCoordinateKey:@"xKey"
                                           yCoordinateKey:@"yKey"];
    provider = [model provider];

    LTParameterizationKeyToValues *mapping =
        [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                               valuesPerKey:(cv::Mat1g(2, 2) << 5, 6, 7, 8)];
    additionalSamples = [[LTSampleValues alloc] initWithSampledParametricValues:{2, 3}
                                                                        mapping:mapping];
  });

  it(@"should provide quads rotated according to spline direction", ^{
    dvn::GeometryValues values = [provider valuesFromSamples:samples end:NO];
    values = [provider valuesFromSamples:additionalSamples end:NO];
    std::vector<lt::Quad> quads = values.quads();
    CGPoint firstCenter = CGPointMake(5, 7);
    CGPoint secondCenter = CGPointMake(6, 8);
    CGFloat angle = LTVector2(secondCenter - firstCenter).angle(LTVector2(1, 0));

    std::vector<lt::Quad> expectedQuads = {
      lt::Quad(CGRectCenteredAt(firstCenter, size)).rotatedAroundPoint(-angle, firstCenter),
      lt::Quad(CGRectCenteredAt(secondCenter, size)).rotatedAroundPoint(-angle, secondCenter)
    };

    expect(quads.size()).to.equal(expectedQuads.size());
    for (std::vector<lt::Quad>::size_type i = 0; i < quads.size(); ++i) {
      expect(quads[i] == expectedQuads[i]).to.beTruthy();
    }
  });
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  DVNDirectedRectProviderModel *model = [[DVNDirectedRectProviderModel alloc] initWithSize:size];
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[
    @instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation),
    @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)]
  ];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];
  NSArray<NSValue *> *expectedQuads = DVNConvertedBoxedQuadsFromQuads({
    lt::Quad(CGRectCenteredAt(CGPointMake(1, 3), size)),
    lt::Quad(CGRectCenteredAt(CGPointMake(2, 4), size))
  });
  std::vector<NSUInteger> indices = {0, 1};
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples,
    kDVNGeometryProviderExamplesExpectedQuads: expectedQuads,
    kDVNGeometryProviderExamplesExpectedIndices: $(indices)
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      DVNDirectedRectProviderModel *model =
          [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                              yCoordinateKey:@"yKey"];
      id<DVNGeometryProvider> provider = [model provider];
      [provider valuesFromSamples:samples end:NO];
      DVNDirectedRectProviderModel *currentModel = [provider currentModel];

      expect(currentModel).toNot.equal(model);
      expect(currentModel.size).to.equal(model.size);
      expect(currentModel.xCoordinateKey).to.equal(model.xCoordinateKey);
      expect(currentModel.yCoordinateKey).to.equal(model.yCoordinateKey);
    });
  });

  context(@"invalid calls", ^{
    it(@"should raise when attempting to retrieve quads from sample values with invalid keys", ^{
      DVNDirectedRectProviderModel *model =
          [[DVNDirectedRectProviderModel alloc] initWithSize:size];
      NSOrderedSet *insufficientKeys = [NSOrderedSet orderedSetWithObject:@"xKey"];
      LTParameterizationKeyToValues *mapping =
          [[LTParameterizationKeyToValues alloc] initWithKeys:insufficientKeys
                                                 valuesPerKey:(cv::Mat1g(1, 1) << 0)];
      samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0} mapping:mapping];
      expect(^{
        [[model provider] valuesFromSamples:samples end:NO];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to retrieve quads from sample values with invalid keys", ^{
      DVNDirectedRectProviderModel *model =
          [[DVNDirectedRectProviderModel alloc] initWithSize:size xCoordinateKey:@"xKey"
                                              yCoordinateKey:@"yKey"];
      NSOrderedSet *insufficientKeys = [NSOrderedSet orderedSetWithObject:@"xKey"];
      LTParameterizationKeyToValues *mapping =
          [[LTParameterizationKeyToValues alloc] initWithKeys:insufficientKeys
                                                 valuesPerKey:(cv::Mat1g(1, 1) << 0)];
      samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0} mapping:mapping];
      expect(^{
        [[model provider] valuesFromSamples:samples end:NO];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

SpecEnd
