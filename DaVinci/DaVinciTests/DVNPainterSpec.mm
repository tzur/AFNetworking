// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPainter.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNSplineRenderModel.h"
#import "DVNTestPipelineConfiguration.h"

@interface DVNTestSplineRenderInfoProvider : NSObject <DVNBrushRenderInfoProvider>
@property (strong, nonatomic) LTParameterizedObjectType *typeOfParameterizedObjectForBrushRendering;
@property (nonatomic) NSUInteger numberOfParameterizedObjectTypeRequests;
@property (strong, nonatomic) DVNPipelineConfiguration *pipelineConfigurationForBrushRendering;
@end

@implementation DVNTestSplineRenderInfoProvider
@end

static NSString * const kDVNBrushRenderInfoProviderExamples = @"DVNBrushRenderInfoProviderExamples";
static NSString * const kLTParameterizedObjectType = @"LTParameterizedObjectType";

SharedExamplesBegin(LTParameterizedObjectType)

sharedExamplesFor(kDVNBrushRenderInfoProviderExamples, ^(NSDictionary *data) {
  __block LTTexture *canvas;
  __block id providerMock;
  __block DVNPainter *painter;
  __block LTParameterizedObjectType *type;
  __block DVNPipelineConfiguration *configuration;

  beforeEach(^{
    canvas = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
    providerMock = OCMProtocolMock(@protocol(DVNBrushRenderInfoProvider));
    [providerMock setExpectationOrderMatters:YES];
    painter =
        [[DVNPainter alloc] initWithCanvas:canvas brushRenderInfoProvider:providerMock
                                  delegate:nil];
    type = data[kLTParameterizedObjectType];
    configuration = DVNTestPipelineConfiguration();
  });

  afterEach(^{
    configuration = nil;
    type = nil;
    painter = nil;
    providerMock = nil;
    canvas = nil;
  });

  context(@"parameterized object type", ^{
    it(@"should request parameterized object type from provider", ^{
      OCMStub([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);
      OCMExpect([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should request parameterized object type from provider for every process sequence "
       "start", ^{
      OCMStub([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);

      // First process sequence.
      OCMExpect([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);

      [painter processControlPoints:@[] end:YES];

      OCMVerifyAll(providerMock);

      // Second process sequence.
      OCMExpect([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should not request parameterized object type from provider during process sequence", ^{
      OCMStub([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);
      OCMExpect([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMReject([providerMock typeOfParameterizedObjectForBrushRendering]);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });
  });

  context(@"provider", ^{
    it(@"should request pipeline configuration from provider", ^{
      OCMStub([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);
      OCMExpect([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should request pipeline configuration from provider for every process sequence start", ^{
      OCMStub([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);

      // First process sequence.
      OCMExpect([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);

      [painter processControlPoints:@[] end:YES];

      OCMVerifyAll(providerMock);

      // Second process sequence.
      OCMExpect([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should not request pipeline configuration from provider during process sequence", ^{
      OCMStub([providerMock typeOfParameterizedObjectForBrushRendering]).andReturn(type);
      OCMExpect([providerMock pipelineConfigurationForBrushRendering]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMReject([providerMock pipelineConfigurationForBrushRendering]);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });
  });

  it(@"should raise if provider is deallocated before start of last process sequence", ^{
    @autoreleasepool {
      id<DVNBrushRenderInfoProvider> volatileProvider =
          OCMProtocolMock(@protocol(DVNBrushRenderInfoProvider));
      painter = [[DVNPainter alloc] initWithCanvas:canvas
                           brushRenderInfoProvider:volatileProvider delegate:nil];
    };

    expect(^{
      [painter processControlPoints:@[] end:NO];
    }).to.raise(NSInternalInconsistencyException);
  });
});

SharedExamplesEnd

SpecBegin(DVNPainter)

context(@"initialization", ^{
  __block LTTexture *canvas;
  __block id providerMock;
  __block id delegateMock;

  beforeEach(^{
    canvas = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
    providerMock = OCMProtocolMock(@protocol(DVNBrushRenderInfoProvider));
    delegateMock = OCMProtocolMock(@protocol(DVNPainterDelegate));
  });

  afterEach(^{
    delegateMock = nil;
    providerMock = nil;
    canvas = nil;
  });

  it(@"should initialize without delegate", ^{
    DVNPainter *painter = [[DVNPainter alloc] initWithCanvas:canvas
                                     brushRenderInfoProvider:providerMock delegate:nil];
    expect(painter).toNot.beNil();
  });

  it(@"should initialize with delegate", ^{
    DVNPainter *painter = [[DVNPainter alloc] initWithCanvas:canvas
                                     brushRenderInfoProvider:providerMock delegate:delegateMock];
    expect(painter).toNot.beNil();
  });

  it(@"should set the delegate with the one given upon initialization", ^{
    DVNPainter *painter = [[DVNPainter alloc] initWithCanvas:canvas
                                     brushRenderInfoProvider:providerMock delegate:delegateMock];
    expect(painter.delegate).to.equal(delegateMock);
  });
});

context(@"retrieval of data from DVNBrushRenderInfoProvider", ^{
  [LTParameterizedObjectType enumerateEnumUsingBlock:^(LTParameterizedObjectType *value) {
    itShouldBehaveLike(kDVNBrushRenderInfoProviderExamples, @{
      kLTParameterizedObjectType: value
    });
  }];
});

it(@"should cause the generation ID of the canvas to update when processing models", ^{
  LTControlPointModel *controlPointModel =
      [[LTControlPointModel alloc] initWithType:$(LTParameterizedObjectTypeLinear)];
  DVNSplineRenderModel *model =
      [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                configuration:DVNTestPipelineConfiguration()
                                                  endInterval:lt::Interval<CGFloat>()];

  LTTexture *canvas = [LTTexture byteRGBATextureWithSize:CGSizeMake(1, 1)];
  NSString *generationID = canvas.generationID;

  [DVNPainter processModels:@[model] usingCanvas:canvas];

  expect(canvas.generationID).toNot.equal(generationID);
});

SpecEnd
