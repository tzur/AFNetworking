// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushStrokePainter.h"

#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTGLContext.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSplineControlPoint+AttributeKeys.h>
#import <LTEngine/LTTexture+Factory.h>

#import "DVNBrushModel+Deserialization.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"
#import "DVNBrushStroke.h"
#import "DVNPipelineConfiguration.h"
#import "DVNSplineRenderModel.h"
#import "DVNTestObserver.h"

@interface DVNTestBrushStrokePainterDelegate : NSObject <DVNBrushStrokePainterDelegate>

@property (strong, nonatomic, nullable) LTParameterizedObjectType *type;
@property (strong, nonatomic) DVNBrushRenderModel *brushRenderModel;
@property (strong, nonatomic) NSDictionary<NSString *, LTTexture *> *textureMapping;
@property (strong, nonatomic, nullable) LTTexture *canvas;
@property (strong, nonatomic, nullable) LTTexture *helpCanvas;

@property (readonly, nonatomic) NSUInteger numberOfInfoRetrievals;
@property (readonly, nonatomic) NSUInteger numberOfCanvasRetrievals;
@property (readonly, nonatomic) NSUInteger numberOfAuxiliaryCanvasRetrievals;
@property (readonly, nonatomic) NSUInteger numberOfTypeRetrievals;

@property (readonly, nonatomic) NSUInteger numberOfBrushStrokePaintingStartEvents;
@property (readonly, nonatomic) std::vector<lt::Quad> quads;
@property (readonly, nonatomic) DVNBrushStrokeSpecification *brushStroke;

@end

@implementation DVNTestBrushStrokePainterDelegate

- (std::pair<DVNBrushRenderModel *, NSDictionary<NSString *, LTTexture *> *>)brushStrokeData {
  ++_numberOfInfoRetrievals;
  return {self.brushRenderModel, self.textureMapping};
}

- (nullable LTTexture *)brushStrokeCanvas {
  ++_numberOfCanvasRetrievals;
  return self.canvas;
}

- (LTTexture *)auxiliaryCanvas {
  ++_numberOfAuxiliaryCanvasRetrievals;
  return self.helpCanvas;
}

- (BOOL)respondsToSelector:(SEL)selector {
  if (selector != @selector(brushSplineType)) {
    return [super respondsToSelector:selector];
  }
  return self.type != nil;
}

- (LTParameterizedObjectType *)brushSplineType {
  ++_numberOfTypeRetrievals;
  return self.type;
}

- (void)renderingOfPainterWillStart:(DVNBrushStrokePainter __unused *)painter {
  ++_numberOfBrushStrokePaintingStartEvents;
}

- (void)renderingOfPainter:(DVNBrushStrokePainter __unused *)painter
        continuedWithQuads:(const std::vector<lt::Quad> &)quads {
  _quads = quads;
}

- (void)renderingOfPainter:(DVNBrushStrokePainter __unused *)painter
      endedWithBrushStroke:(DVNBrushStrokeSpecification *)brushStroke {
  _brushStroke = brushStroke;
}

@end

@interface DVNBrushStrokePainter () <DVNSplineRenderingDelegate>
@end

SpecBegin(DVNBrushStrokePainter)

static const CGSize kSize = CGSizeMake(37, 7);

__block DVNBrushModel *brushModel;
__block DVNTestBrushStrokePainterDelegate *delegate;
__block DVNBrushStrokePainter *painter;
__block LTParameterizedObjectType *type;

beforeEach(^{
  NSString *filePath = [[NSBundle bundleForClass:[self class]]
                        pathForResource:@"DVNDefaultTestBrushModelV1" ofType:@"json"];
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data
                                                             options:(NSJSONReadingOptions)0
                                                               error:nil];
  brushModel = [DVNBrushModel modelFromJSONDictionary:dictionary error:nil];
  lt::Quad quad(CGRectFromSize(kSize));
  DVNBrushRenderTargetInformation *renderTargetInfo =
      [DVNBrushRenderTargetInformation instanceWithRenderTargetLocation:quad
                                           renderTargetHasSingleChannel:NO
                                         renderTargetIsNonPremultiplied:NO
                                           renderTargetHasBytePrecision:YES];

  delegate = [[DVNTestBrushStrokePainterDelegate alloc] init];
  delegate.brushRenderModel = [DVNBrushRenderModel instanceWithBrushModel:brushModel
                                                         renderTargetInfo:renderTargetInfo
                                                         conversionFactor:1];
  delegate.textureMapping = @{
    @"sourceImageURL": OCMClassMock([LTTexture class]),
    @"maskImageURL": OCMClassMock([LTTexture class]),
    @"edgeAvoidanceGuideImageURL": @""
  };
  delegate.canvas = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
  delegate.type = $(LTParameterizedObjectTypeLinear);

  painter = [[DVNBrushStrokePainter alloc] initWithDelegate:delegate];
});

afterEach(^{
  delegate = nil;
  painter = nil;
  type = nil;
});

context(@"initialization", ^{
  it(@"should initialize with delegate", ^{
    expect(painter).toNot.beNil();
    expect(painter.delegate).to.equal(delegate);
  });

  it(@"should weakly hold its delegate", ^{
    __weak id<DVNBrushStrokePainterDelegate> weaklyHeldDelegate;
    @autoreleasepool {
      id<DVNBrushStrokePainterDelegate> volatileDelegate =
          OCMProtocolMock(@protocol(DVNBrushStrokePainterDelegate));
      painter = [[DVNBrushStrokePainter alloc] initWithDelegate:volatileDelegate];
      weaklyHeldDelegate = volatileDelegate;
      expect(painter.delegate).to.equal(weaklyHeldDelegate);
    }
    expect(painter.delegate).to.beNil;
  });

  it(@"should correctly deallocate", ^{
    __weak DVNBrushStrokePainter *weaklyHeldPainter;

    @autoreleasepool {
      DVNBrushStrokePainter * painter = [[DVNBrushStrokePainter alloc] initWithDelegate:delegate];
      weaklyHeldPainter = painter;
      expect(weaklyHeldPainter).toNot.beNil();
    }
    expect(weaklyHeldPainter).to.beNil();
  });
});

context(@"information retrieval at beginning and continuation of process sequences", ^{
  context(@"brush stroke info retrieval", ^{
    it(@"should retrieve brush stroke info from delegate", ^{
      expect(delegate.numberOfInfoRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfInfoRetrievals).to.equal(1);
    });

    it(@"should retrieve brush stroke info from delegate at beginning of process sequence", ^{
      expect(delegate.numberOfInfoRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:YES];
      expect(delegate.numberOfInfoRetrievals).to.equal(1);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfInfoRetrievals).to.equal(2);
    });

    it(@"should retrieve brush stroke info from delegate only at beginning of process sequence", ^{
      expect(delegate.numberOfInfoRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfInfoRetrievals).to.equal(1);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfInfoRetrievals).to.equal(1);
    });
  });

  context(@"brush stroke canvas retrieval", ^{
    it(@"should retrieve canvas from delegate", ^{
      expect(delegate.numberOfCanvasRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfCanvasRetrievals).to.equal(1);
    });

    it(@"should retrieve canvas from delegate at every process sequence continuation", ^{
      expect(delegate.numberOfCanvasRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfCanvasRetrievals).to.equal(1);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfCanvasRetrievals).to.equal(2);
    });
  });

  context(@"brush spline type retrieval", ^{
    it(@"should retrieve spline type from delegate", ^{
      expect(delegate.numberOfTypeRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfTypeRetrievals).to.equal(1);
    });

    it(@"should retrieve spline type from delegate at beginning of process sequence", ^{
      expect(delegate.numberOfTypeRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:YES];
      expect(delegate.numberOfTypeRetrievals).to.equal(1);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfTypeRetrievals).to.equal(2);
    });

    it(@"should retrieve spline type from delegate only at beginning of process sequence", ^{
      expect(delegate.numberOfTypeRetrievals).to.equal(0);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfTypeRetrievals).to.equal(1);
      [painter processControlPoints:@[] end:NO];
      expect(delegate.numberOfTypeRetrievals).to.equal(1);
    });
  });

  it(@"should raise if delegate is deallocated before start of last process sequence", ^{
    @autoreleasepool {
      id<DVNBrushStrokePainterDelegate> volatileDelegate =
          OCMProtocolMock(@protocol(DVNBrushStrokePainterDelegate));
      painter = [[DVNBrushStrokePainter alloc] initWithDelegate:volatileDelegate];
    };

    expect(^{
      [painter processControlPoints:@[] end:NO];
    }).to.raise(NSInternalInconsistencyException);
  });
});

context(@"delegate information", ^{
  __block id<DVNSplineRendering> splineRendererMock;

  beforeEach(^{
    splineRendererMock = OCMProtocolMock(@protocol(DVNSplineRendering));
  });

  it(@"should inform delegate about beginning of brush stroke painting", ^{
    expect(delegate.numberOfBrushStrokePaintingStartEvents).to.equal(0);
    [painter renderingOfSplineRendererWillStart:splineRendererMock];
    expect(delegate.numberOfBrushStrokePaintingStartEvents).to.equal(1);
  });

  it(@"should inform delegate about continuation of brush stroke painting", ^{
    std::vector<lt::Quad> quads = {lt::Quad::canonicalSquare()};
    expect(delegate.quads == quads).to.beFalsy();
    [painter renderingOfSplineRenderer:splineRendererMock continuedWithQuads:quads];
    expect(delegate.quads == quads).to.beTruthy();
  });

  it(@"should inform delegate about end of brush stroke painting", ^{
    [painter processControlPoints:@[] end:NO];

    expect(delegate.brushStroke).to.beNil();
    LTControlPointModel *controlPointModel = OCMClassMock([LTControlPointModel class]);
    DVNPipelineConfiguration *configuration = OCMClassMock([DVNPipelineConfiguration class]);
    lt::Interval<CGFloat> interval({7, 8});
    DVNSplineRenderModel *model =
        [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                  configuration:configuration
                                                    endInterval:interval];

    [painter renderingOfSplineRenderer:splineRendererMock endedWithModel:model];

    expect(delegate.brushStroke).toNot.beNil();
    expect(delegate.brushStroke.controlPointModel).to.equal(controlPointModel);
    expect(delegate.brushStroke.brushRenderModel).to.equal(delegate.brushRenderModel);
    expect(delegate.brushStroke.endInterval == interval).to.beTruthy();
  });

  it(@"should inform delegate about end of painting of random brush stroke", ^{
    brushModel = [brushModel copyWithRandomInitialSeed:YES];
    delegate.brushRenderModel = [delegate.brushRenderModel copyWithBrushModel:brushModel];

    [painter processControlPoints:@[] end:NO];

    expect(delegate.brushStroke).to.beNil();
    LTControlPointModel *controlPointModel = OCMClassMock([LTControlPointModel class]);
    DVNPipelineConfiguration *configuration = OCMClassMock([DVNPipelineConfiguration class]);
    lt::Interval<CGFloat> interval({7, 8});
    DVNSplineRenderModel *model =
        [[DVNSplineRenderModel alloc] initWithControlPointModel:controlPointModel
                                                  configuration:configuration
                                                    endInterval:interval];

    [painter renderingOfSplineRenderer:splineRendererMock endedWithModel:model];

    DVNBrushModel *delegateBrushModel = delegate.brushStroke.brushRenderModel.brushModel;
    brushModel = [[brushModel copyWithRandomInitialSeed:NO]
                  copyWithInitialSeed:delegateBrushModel.initialSeed];
    DVNBrushRenderModel *brushRenderModel =
        [delegate.brushRenderModel copyWithBrushModel:brushModel];

    expect(delegate.brushStroke).toNot.beNil();
    expect(delegate.brushStroke.controlPointModel).to.equal(controlPointModel);
    expect(delegate.brushStroke.brushRenderModel).toNot.equal(delegate.brushRenderModel);
    expect(delegate.brushStroke.brushRenderModel).to.equal(brushRenderModel);
    expect(delegate.brushStroke.endInterval == interval).to.beTruthy();
  });
});

context(@"properties", ^{
  it(@"should provide spline processing indication correctly", ^{
    DVNBrushStrokePainter *painter = [[DVNBrushStrokePainter alloc] initWithDelegate:delegate];

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

context(@"brush stroke painting", ^{
  static NSDictionary<NSString *, NSNumber *> *kAttributes = @{
    [LTSplineControlPoint keyForSpeedInScreenCoordinates]: @0
  };

  static NSArray<LTSplineControlPoint *> * const kControlPoints = @[
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(3.5,
                                                                           kSize.height / 2)
                                         attributes:kAttributes],
    [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(kSize.width - 3.5,
                                                                           kSize.height / 2)
                                         attributes:kAttributes]
  ];

  __block LTTexture *sourceTexture;
  __block LTTexture *maskTexture;
  __block cv::Mat expected;

  beforeEach(^{
    delegate.canvas = [LTTexture byteRGBATextureWithSize:kSize];
    [delegate.canvas clearColor:LTVector4::zeros()];
    sourceTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
    [sourceTexture clearColor:LTVector4::ones()];
    maskTexture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
    [maskTexture clearColor:LTVector4::ones()];

    delegate.textureMapping = @{
      @"sourceImageURL": sourceTexture,
      @"maskImageURL": maskTexture
    };

    expected = LTLoadMat([self class], @"DVNBrushModelV1_Default.png");
  });

  it(@"should correctly paint given brush strokes", ^{
    [painter processControlPoints:kControlPoints end:YES];
    expect($(delegate.canvas.image)).to.equalMat($(expected));
  });

  it(@"should correctly paint brush stroke previously created by painter", ^{
    [painter processControlPoints:kControlPoints end:YES];
    DVNBrushStrokeSpecification *brushStrokeSpecification = delegate.brushStroke;

    DVNBrushStrokeData *data =
        [DVNBrushStrokeData dataWithSpecification:brushStrokeSpecification
                                   textureMapping:delegate.textureMapping];

    [DVNBrushStrokePainter paintBrushStrokesAccordingToData:@[data]
                                                 ontoCanvas:delegate.canvas];

    expect($(delegate.canvas.image)).to.equalMat($(expected));
  });

  context(@"smoothing", ^{
    __block NSArray<LTSplineControlPoint *> *points;

    beforeEach(^{
      points = @[
        [[LTSplineControlPoint alloc] initWithTimestamp:0 location:CGPointMake(1.5, 1.5)
                                             attributes:kAttributes],
        [[LTSplineControlPoint alloc] initWithTimestamp:1
                                               location:CGPointMake(kSize.width - 1.5, 1.5)
                                             attributes:kAttributes],
        [[LTSplineControlPoint alloc] initWithTimestamp:2
                                               location:CGPointMake(kSize.width - 1.5,
                                                                    kSize.height - 1.5)
                                             attributes:kAttributes],
        [[LTSplineControlPoint alloc] initWithTimestamp:3
                                               location:CGPointMake(1.5, kSize.height - 1.5)
                                             attributes:kAttributes],
        [[LTSplineControlPoint alloc] initWithTimestamp:4 location:CGPointMake(1.5, 1.5)
                                             attributes:kAttributes]
      ];
      brushModel = [brushModel copyWithSplineSmoothness:0.75];
      delegate.brushRenderModel = [delegate.brushRenderModel copyWithBrushModel:brushModel];
      delegate.helpCanvas = [delegate.canvas clone];
      expected = LTLoadMat([self class], @"DVNBrushModelV1_Smoothing.png");
    });

    it(@"should correctly paint a smoothed stroke", ^{
      expect(delegate.numberOfAuxiliaryCanvasRetrievals).to.equal(0);
      [painter processControlPoints:points end:YES];
      expect(delegate.numberOfAuxiliaryCanvasRetrievals).to.equal(1);
      expect($(delegate.canvas.image)).to.equalMat($(expected));
    });
  });

});

SpecEnd
