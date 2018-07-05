// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNJitteredColorAttributeProviderModel.h"

#import <LTEngine/LTParameterizationKeyToValues.h>
#import <LTEngine/LTQuad.h>
#import <LTEngine/LTSampleValues.h>
#import <LTKit/LTRandom.h>
#import <LTKitTestUtils/LTEqualityExamples.h>

#import "DVNAttributeProviderExamples.h"
#import "DVNEasyQuadVectorBoxing.h"

SpecBegin(DVNJitteredColorAttributeProviderModel)

__block LTVector3 baseColor;
__block CGFloat brightnessJitter;
__block CGFloat hueJitter;
__block CGFloat saturationJitter;
__block LTRandomState *randomState;
__block DVNJitteredColorAttributeProviderModel *model;

beforeEach(^{
  baseColor = LTVector3(0.25, 0.5, 0.75);
  brightnessJitter = 0.3;
  hueJitter = 0.4;
  saturationJitter = 0.5;
  randomState = [[LTRandom alloc] initWithSeed:0].engineState;
  model = [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                           brightnessJitter:brightnessJitter
                                                                  hueJitter:hueJitter
                                                           saturationJitter:saturationJitter
                                                                randomState:randomState];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(model).toNot.beNil();
  });

  it(@"should have correct initial property values", ^{
    expect(model.baseColor).to.equal(baseColor);
    expect(model.brightnessJitter).to.equal(brightnessJitter);
    expect(model.hueJitter).to.equal(hueJitter);
    expect(model.saturationJitter).to.equal(saturationJitter);
    expect(model.randomState).to.equal(randomState);
  });

  context(@"invalid initialization attempts", ^{
    it(@"should raise when attempting to initialize out of range brightness jitter", ^{
      expect(^{
        model = [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                                 brightnessJitter:2
                                                                        hueJitter:hueJitter
                                                                 saturationJitter:saturationJitter
                                                                      randomState:randomState];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize out of range hue jitter", ^{
      expect(^{
        model = [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                                 brightnessJitter:brightnessJitter
                                                                        hueJitter:2
                                                                 saturationJitter:saturationJitter
                                                                      randomState:randomState];
      }).to.raise(NSInvalidArgumentException);
    });

    it(@"should raise when attempting to initialize out of range saturation jitter", ^{
      expect(^{
        model = [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                                 brightnessJitter:brightnessJitter
                                                                        hueJitter:hueJitter
                                                                 saturationJitter:2
                                                                      randomState:randomState];
      }).to.raise(NSInvalidArgumentException);
    });
  });
});

itShouldBehaveLike(kLTEqualityExamples, ^{
  DVNJitteredColorAttributeProviderModel *equalModel =
      [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                       brightnessJitter:brightnessJitter
                                                              hueJitter:hueJitter
                                                       saturationJitter:saturationJitter
                                                            randomState:randomState];
  NSArray *differentObjects = @[
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor + LTVector3::ones()
                                                     brightnessJitter:brightnessJitter
                                                            hueJitter:hueJitter
                                                     saturationJitter:saturationJitter
                                                          randomState:randomState],
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                     brightnessJitter:brightnessJitter + 0.1
                                                            hueJitter:hueJitter
                                                     saturationJitter:saturationJitter
                                                          randomState:randomState],
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                     brightnessJitter:brightnessJitter
                                                            hueJitter:hueJitter + 0.1
                                                     saturationJitter:saturationJitter
                                                          randomState:randomState],
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                     brightnessJitter:brightnessJitter
                                                            hueJitter:hueJitter
                                                     saturationJitter:saturationJitter + 0.1
                                                          randomState:randomState],
    [[DVNJitteredColorAttributeProviderModel alloc] initWithBaseColor:baseColor
                                                     brightnessJitter:brightnessJitter
                                                            hueJitter:hueJitter
                                                     saturationJitter:saturationJitter + 0.1
                                                          randomState:[[LTRandomState alloc] init]]
  ];
  return @{
    kLTEqualityExamplesObject: model,
    kLTEqualityExamplesEqualObject: equalModel,
    kLTEqualityExamplesDifferentObjects: differentObjects
  };
});

itShouldBehaveLike(kDVNAttributeProviderExamples, ^{
  LTQuad *quad = [LTQuad quadFromRect:CGRectFromSize(CGSizeMakeUniform(1))];
  NSOrderedSet<NSString *> *keys = [NSOrderedSet orderedSetWithObject:@[@"foo"]];
  LTParameterizationKeyToValues *mapping =
      [[LTParameterizationKeyToValues alloc] initWithKeys:keys valuesPerKey:(cv::Mat1g(1, 1) << 1)];
  LTSampleValues *samples = [[LTSampleValues alloc] initWithSampledParametricValues:{0}
                                                                            mapping:mapping];
  LTGPUStruct *gpuStruct = [[LTGPUStructRegistry sharedInstance]
                            structForName:@"DVNJitteredColorAttributeProviderStruct"];
  std::vector<DVNJitteredColorAttributeProviderStruct> values(6, {
    .colorRed = (GLubyte)(baseColor.r() * 255),
    .colorGreen = (GLubyte)(baseColor.g() * 255),
    .colorBlue = (GLubyte)(baseColor.b() * 255)
  });
  NSData *data = [NSData dataWithBytes:values.data() length:values.size() * sizeof(values[0])];
  DVNJitteredColorAttributeProviderModel *model = [[DVNJitteredColorAttributeProviderModel alloc]
                                                   initWithBaseColor:baseColor brightnessJitter:0
                                                   hueJitter:0 saturationJitter:0
                                                   randomState:randomState];
  return @{
    kDVNAttributeProviderExamplesModel: model,
    kDVNAttributeProviderExamplesInputQuads: @[quad],
    kDVNAttributeProviderExamplesInputIndices: @[@0],
    kDVNAttributeProviderExamplesInputSample: samples,
    kDVNAttributeProviderExamplesExpectedData: data,
    kDVNAttributeProviderExamplesExpectedGPUStruct: gpuStruct
  };
});

context(@"provider", ^{
  context(@"model", ^{
    it(@"should provide a correct updated model", ^{
      id<DVNAttributeProvider> provider = [model provider];
      dvn::GeometryValues values({lt::Quad()}, {0}, OCMClassMock([LTSampleValues class]));
      [provider attributeDataFromGeometryValues:values];
      DVNJitteredColorAttributeProviderModel *currentModel = [provider currentModel];
      expect(currentModel).toNot.equal(model);
    });
  });
});

SpecEnd
