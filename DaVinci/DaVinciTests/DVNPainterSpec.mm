// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPainter.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNBrushRenderInfoProvider.h"
#import "DVNSplineRenderModel.h"
#import "DVNTestObserver.h"
#import "DVNTestPipelineConfiguration.h"

@interface DVNTestSplineRenderInfoProvider : NSObject <DVNBrushRenderInfoProvider>
@property (strong, nonatomic) LTParameterizedObjectType *brushSplineType;
@property (nonatomic) NSUInteger numberOfParameterizedObjectTypeRequests;
@property (strong, nonatomic) DVNPipelineConfiguration *brushRenderConfiguration;
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
      OCMStub([providerMock brushRenderConfiguration]).andReturn(configuration);
      OCMExpect([providerMock brushSplineType]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should request parameterized object type from provider for every process sequence "
       "start", ^{
      OCMStub([providerMock brushRenderConfiguration]).andReturn(configuration);

      // First process sequence.
      OCMExpect([providerMock brushSplineType]).andReturn(type);

      [painter processControlPoints:@[] end:YES];

      OCMVerifyAll(providerMock);

      // Second process sequence.
      OCMExpect([providerMock brushSplineType]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should not request parameterized object type from provider during process sequence", ^{
      OCMStub([providerMock brushRenderConfiguration]).andReturn(configuration);
      OCMExpect([providerMock brushSplineType]).andReturn(type);

      [painter processControlPoints:@[] end:NO];

      OCMReject([providerMock brushSplineType]);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });
  });

  context(@"provider", ^{
    it(@"should request pipeline configuration from provider", ^{
      OCMStub([providerMock brushSplineType]).andReturn(type);
      OCMExpect([providerMock brushRenderConfiguration]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should request pipeline configuration from provider for every process sequence start", ^{
      OCMStub([providerMock brushSplineType]).andReturn(type);

      // First process sequence.
      OCMExpect([providerMock brushRenderConfiguration]).andReturn(configuration);

      [painter processControlPoints:@[] end:YES];

      OCMVerifyAll(providerMock);

      // Second process sequence.
      OCMExpect([providerMock brushRenderConfiguration]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMVerifyAll(providerMock);
    });

    it(@"should not request pipeline configuration from provider during process sequence", ^{
      OCMStub([providerMock brushSplineType]).andReturn(type);
      OCMExpect([providerMock brushRenderConfiguration]).andReturn(configuration);

      [painter processControlPoints:@[] end:NO];

      OCMReject([providerMock brushRenderConfiguration]);

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

  it(@"should provide spline processing indication correctly", ^{
    DVNPainter *painter = [[DVNPainter alloc] initWithCanvas:canvas
                                     brushRenderInfoProvider:providerMock delegate:delegateMock];
    OCMStub([providerMock brushRenderConfiguration]).andReturn(DVNTestPipelineConfiguration());
    OCMStub([providerMock brushSplineType]).andReturn($(LTParameterizedObjectTypeBSpline));

    DVNTestObserver *observer = [[DVNTestObserver alloc] init];
    [painter addObserver:observer
              forKeyPath:@keypath(painter, currentlyProcessingContentTouchEventSequence)
                 options:NSKeyValueObservingOptionNew context:nil];

    [painter processControlPoints:@[] end:NO];
    expect(observer.observedValue).to.beTruthy();
    [painter processControlPoints:@[] end:YES];
    expect(observer.observedValue).to.beFalsy();
    [painter processControlPoints:@[] end:NO];
    expect(observer.observedValue).to.beTruthy();

    [painter removeObserver:observer
                 forKeyPath:@keypath(painter, currentlyProcessingContentTouchEventSequence)
                    context:nil];
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
  NSArray<LTSplineControlPoint *> *controlPoints = @[
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointZero],
    [[LTSplineControlPoint alloc] initWithTimestamp:1 location:CGPointMake(0, 1)]
  ];
  LTControlPointModel *controlPointModel =
      [[LTControlPointModel alloc] initWithType:$(LTParameterizedObjectTypeLinear)
                                  controlPoints:controlPoints];
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
