// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSquareProvider.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTSampleValues.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngineTests/LTEasyVectorBoxing.h>
#import <LTKitTests/LTEqualityExamples.h>

#import "DVNEasyQuadVectorBoxing.h"
#import "DVNGeometryProviderExamples.h"

SpecBegin(DVNSquareProvider)

__block id<LTSampleValues> samples;

beforeEach(^{
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[@"xKey", @"yKey"]];
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
    DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7];
    expect(model).toNot.beNil();
    expect(model.edgeLength).to.equal(7);
    expect(model.xCoordinateKey)
        .to.equal(@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation));
    expect(model.yCoordinateKey)
        .to.equal(@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation));
  });

  it(@"should initialize with given edge length and keys", ^{
    DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                        xCoordinateKey:@"xKey"
                                                                        yCoordinateKey:@"yKey"];
    expect(model).toNot.beNil();
    expect(model.edgeLength).to.equal(7);
    expect(model.xCoordinateKey).to.equal(@"xKey");
    expect(model.yCoordinateKey).to.equal(@"yKey");
  });

  context(@"invalid initialization attempts", ^{
    it(@"should raise when attempting to initialize with negative edge length", ^{
      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:-1];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:-1 xCoordinateKey:@"xKey"
                                                yCoordinateKey:@"yKey"];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with zero edge length", ^{
      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:0];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:0 xCoordinateKey:@"xKey"
                                                yCoordinateKey:@"yKey"];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with empty key", ^{
      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:1 xCoordinateKey:@"xKey"
                                                yCoordinateKey:@""];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize with equal keys", ^{
      expect(^{
        DVNSquareProviderModel * __unused model =
            [[DVNSquareProviderModel alloc] initWithEdgeLength:1 xCoordinateKey:@"key"
                                                yCoordinateKey:@"key"];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7];
  DVNSquareProviderModel *equalModel = [[DVNSquareProviderModel alloc] initWithEdgeLength:7];
  DVNSquareProviderModel *differentModel = [[DVNSquareProviderModel alloc] initWithEdgeLength:8];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[differentModel]
  };
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                      xCoordinateKey:@"xKey"
                                                                      yCoordinateKey:@"yKey"];
  DVNSquareProviderModel *equalModel = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                           xCoordinateKey:@"xKey"
                                                                           yCoordinateKey:@"yKey"];
  DVNSquareProviderModel *differentModel =
      [[DVNSquareProviderModel alloc] initWithEdgeLength:8 xCoordinateKey:@"xKey"
                                          yCoordinateKey:@"yKey"];
  DVNSquareProviderModel *anotherDifferentModel =
      [[DVNSquareProviderModel alloc] initWithEdgeLength:7 xCoordinateKey:@"xKey"
                                          yCoordinateKey:@"foo"];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: @[differentModel, anotherDifferentModel]
  };
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                      xCoordinateKey:@"xKey"
                                                                      yCoordinateKey:@"yKey"];
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples
  };
});

itShouldBehaveLike(kDVNDeterministicGeometryProviderExamples, ^{
  DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                      xCoordinateKey:@"xKey"
                                                                      yCoordinateKey:@"yKey"];
  NSArray<NSValue *> *expectedQuads =
      DVNConvertedBoxedQuadsFromQuads({
        lt::Quad(CGRectCenteredAt(CGPointMake(1, 3), CGSizeMakeUniform(7))),
        lt::Quad(CGRectCenteredAt(CGPointMake(2, 4), CGSizeMakeUniform(7)))
      });
  std::vector<NSUInteger> indices = {0, 1};
  return @{
    kDVNGeometryProviderExamplesModel: model,
    kDVNGeometryProviderExamplesSamples: samples,
    kDVNGeometryProviderExamplesExpectedQuads: expectedQuads,
    kDVNGeometryProviderExamplesExpectedIndices: $(indices)
  };
});

itShouldBehaveLike(kDVNGeometryProviderExamples, ^{
  DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7];
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithArray:@[
    @instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation),
    @instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)]
  ];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys
                                             valuesPerKey:(cv::Mat1g(2, 2) << 1, 2, 3, 4)];
  samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0, 1} mapping:mapping];
  NSArray<NSValue *> *expectedQuads =
      DVNConvertedBoxedQuadsFromQuads({
        lt::Quad(CGRectCenteredAt(CGPointMake(1, 3), CGSizeMakeUniform(7))),
        lt::Quad(CGRectCenteredAt(CGPointMake(2, 4), CGSizeMakeUniform(7)))
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
      DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                          xCoordinateKey:@"xKey"
                                                                          yCoordinateKey:@"yKey"];
      id<DVNGeometryProvider> provider = [model provider];
      [provider valuesFromSamples:samples end:NO];
      DVNSquareProviderModel *currentModel = [provider currentModel];
      expect(currentModel).to.equal(model);
    });
  });

  context(@"invalid calls", ^{
    it(@"should raise when attempting to retrieve quads from sample values with invalid keys", ^{
      DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7];
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
      DVNSquareProviderModel *model = [[DVNSquareProviderModel alloc] initWithEdgeLength:7
                                                                          xCoordinateKey:@"xKey"
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
