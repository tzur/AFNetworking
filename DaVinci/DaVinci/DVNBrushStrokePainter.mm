// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushStrokePainter.h"

#import <LTEngine/LTFbo.h>
#import <LTEngine/LTFboPool.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTSpeedBasedSplineControlPointBuffer.h>
#import <LTEngine/LTSplineControlPoint.h>
#import <LTEngine/LTTexture.h>
#import <LTEngine/LTTextureBlitter.h>
#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>

#import "DVNBrushModel.h"
#import "DVNBrushRenderConfigurationProvider.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"
#import "DVNBrushStroke.h"
#import "DVNPainter.h"
#import "DVNSplineControlPointStabilizer.h"
#import "DVNSplineRenderModel.h"
#import "DVNSplineRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNBrushStrokePainter () <DVNSplineRenderingDelegate>

/// Internally used provider of \c DVNPipelineConfiguration objects constructed from the brush
/// stroke information retrieved from the \c delegate of this instance.
@property (readonly, nonatomic) DVNBrushRenderConfigurationProvider *provider;

/// Renderer used to paint onto the render target. Is not \c nil only during a control point
/// sequence.
@property (strong, nonatomic, nullable) DVNSplineRenderer *renderer;

/// Model of brush stroke currently being painted. \c nil if no brush stroke is currently being
/// painted.
@property (strong, nonatomic, nullable) DVNBrushRenderModel *brushRenderModel;

/// Used for copying content between auxiliary and the canvas texture, when smoothing the rendered
/// spline.
@property (readonly, nonatomic) LTTextureBlitter *blitter;

/// Maps the processed control points to obtain a smoother spline when it's rendered.
@property (readonly, nonatomic) DVNSplineControlPointStabilizer *stabilizer;

/// Buffers spline's trailing control points for fade-out smoothing when rendering its ending.
@property (readonly, nonatomic) LTSpeedBasedSplineControlPointBuffer *tailBuffer;

@end

@implementation DVNBrushStrokePainter

#pragma mark -
#pragma mark Initialization
#pragma mark -

/// Defines the maximum speed, in view coordinates, of points which will be buffered for the maximal
/// amount of time.
static const CGFloat kBufferingMaxSpeed = 5000;

/// Time intervals defining the minimal (maximal) buffering timeout for the slowest (fastest)
/// control point.
static const auto kBufferingIntervals = lt::Interval<NSTimeInterval>({0, 0.1});

- (instancetype)initWithDelegate:(id<DVNBrushStrokePainterDelegate>)delegate {
  LTParameterAssert(delegate);

  if (self = [super init]) {
    _delegate = delegate;
    _provider = [[DVNBrushRenderConfigurationProvider alloc] init];
    _blitter = [[LTTextureBlitter alloc] init];
    _stabilizer = [[DVNSplineControlPointStabilizer alloc] init];
    _tailBuffer = [[LTSpeedBasedSplineControlPointBuffer alloc]
                   initWithMaxSpeed:kBufferingMaxSpeed timeIntervals:kBufferingIntervals];
  }
  return self;
}

#pragma mark -
#pragma mark DVNSplineRendering
#pragma mark -

- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end {
  LTAssert(self.delegate);

  if (!self.currentlyProcessingContentTouchEventSequence) {
    [self createRenderer];
  }

  LTTexture * _Nullable canvas = [self.delegate brushStrokeCanvas];
  LTTexture * _Nullable auxiliaryCanvas =
      [self.delegate respondsToSelector:@selector(auxiliaryCanvas)] ?
      [self.delegate auxiliaryCanvas] : nil;
  CGFloat splineSmoothness = self.brushRenderModel.brushModel.splineSmoothness;
  CGFloat splineSmoothnessThreshold = *[self.brushRenderModel.brushModel.class
                                        allowedSplineSmoothnessRange].min();
  BOOL applySmoothing = canvas && auxiliaryCanvas && canvas != auxiliaryCanvas &&
      splineSmoothness > splineSmoothnessThreshold;

  if (applySmoothing) {
    [self renderBrushStrokeAccordingToControlPoints:controlPoints
                              smoothedWithIntensity:splineSmoothness
                                         ontoCanvas:canvas withAuxiliaryCanvas:auxiliaryCanvas
                                                end:end];
  } else {
    [self renderBrushStrokeAccordingToControlPoints:controlPoints ontoCanvas:canvas end:end];
  }

  if (end) {
    [self reset];
  }
}

- (void)cancel {
  [self.renderer cancel];
  [self reset];
}

#pragma mark -
#pragma mark DVNSplineRendering - Auxiliary Methods
#pragma mark -

- (void)reset {
  self.renderer = nil;
  self.brushRenderModel = nil;
  [self.stabilizer reset];
  [self.tailBuffer processAndPossiblyBufferControlPoints:@[] flush:YES];
}

- (void)renderBrushStrokeAccordingToControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints
                                       ontoCanvas:(nullable LTTexture *)canvas end:(BOOL)end {
  if (canvas) {
    [self validateCanvas:canvas];
    [[[LTFboPool currentPool] fboWithTexture:canvas] bindAndDraw:^{
      [self.renderer processControlPoints:controlPoints end:end];
    }];
  } else {
    [self.renderer processControlPoints:controlPoints end:end];
  }
}

- (void)renderBrushStrokeAccordingToControlPoints:(NSArray<LTSplineControlPoint *> *)points
                            smoothedWithIntensity:(CGFloat)smoothingIntensity
                                       ontoCanvas:(LTTexture *)canvas
                              withAuxiliaryCanvas:(LTTexture *)auxiliaryCanvas end:(BOOL)end {
  auto pointsToSmooth = [self.tailBuffer processAndPossiblyBufferControlPoints:points flush:NO];
  auto smoothedPoints = [self.stabilizer pointsForPoints:pointsToSmooth
                                   smoothedWithIntensity:smoothingIntensity preserveState:NO
                                        fadeOutSmoothing:NO];
  LTAssert(self.renderer);

  [self validateCanvas:auxiliaryCanvas];
  [[[LTFboPool currentPool] fboWithTexture:auxiliaryCanvas] bindAndDraw:^{
    [self.renderer processControlPoints:smoothedPoints preserveState:NO end:NO];
  }];

  [self.blitter copyTexture:auxiliaryCanvas toRect:CGRectFromSize(canvas.size)
                  ofTexture:canvas];

  [self validateCanvas:canvas];
  auto tailPoints = [self.stabilizer pointsForPoints:self.tailBuffer.bufferedControlPoints
                               smoothedWithIntensity:smoothingIntensity preserveState:YES
                                    fadeOutSmoothing:YES];
  [[[LTFboPool currentPool] fboWithTexture:canvas] bindAndDraw:^{
    [self.renderer processControlPoints:tailPoints preserveState:!end end:YES];
  }];

  if (end) {
    [self.blitter copyTexture:canvas toRect:CGRectFromSize(auxiliaryCanvas.size)
                    ofTexture:auxiliaryCanvas];
  }
}

- (void)createRenderer {
  LTAssert(!self.renderer);
  LTAssert(!self.brushRenderModel);

  std::pair<DVNBrushRenderModel *, NSDictionary<NSString *, LTTexture *> *>brushStrokeData =
      [self.delegate brushStrokeData];
  DVNBrushRenderModel *brushRenderModel = brushStrokeData.first;
  DVNBrushModel *brushModel = brushRenderModel.brushModel;

  if (brushModel.randomInitialSeed) {
    LTRandom *random = [[LTRandom alloc] init];
    NSUInteger seed =
        (NSUInteger)[random randomUnsignedIntegerBelow:std::numeric_limits<uint>::max()];
    brushModel = [[brushModel copyWithInitialSeed:seed] copyWithRandomInitialSeed:NO];
    brushRenderModel = [brushRenderModel copyWithBrushModel:brushModel];
  }

  self.brushRenderModel = brushRenderModel;

  LTParameterizedObjectType *type = self.brushSplineType;

  DVNPipelineConfiguration *configuration =
      [self.provider configurationForModel:self.brushRenderModel
                        withTextureMapping:brushStrokeData.second];

  self.renderer = [[DVNSplineRenderer alloc] initWithType:type configuration:configuration
                                                 delegate:self];
}

- (void)validateCanvas:(LTTexture *)canvas {
  static NSString * const kSingleChannel = @"single channel";
  static NSString * const kMultipleChannels = @"multiple channels";

  BOOL renderTargetShouldHaveSingleChannel = self.renderTargetInfo.renderTargetHasSingleChannel;
  BOOL renderTargetHasSingleChannel = canvas.components == LTGLPixelComponentsR;

  LTParameterAssert(renderTargetShouldHaveSingleChannel == renderTargetHasSingleChannel,
                    @"Render target info states that render target has %@ but provided canvas has "
                    "%@", renderTargetShouldHaveSingleChannel ? kSingleChannel : kMultipleChannels,
                    renderTargetHasSingleChannel ? kSingleChannel : kMultipleChannels);
}

#pragma mark -
#pragma mark DVNSplineRenderingDelegate
#pragma mark -

- (void)renderingOfSplineRendererWillStart:(__unused id<DVNSplineRendering>)renderer {
  if ([self.delegate respondsToSelector:@selector(renderingOfPainterWillStart:)]) {
    [self.delegate renderingOfPainterWillStart:self];
  }
}

- (void)renderingOfSplineRenderer:(__unused id<DVNSplineRendering>)renderer
               continuedWithQuads:(const std::vector<lt::Quad> &)quads {
  if ([self.delegate
       respondsToSelector:@selector(renderingOfPainter:continuedWithQuads:)]) {
    [self.delegate renderingOfPainter:self continuedWithQuads:quads];
  }
}

- (void)renderingOfSplineRenderer:(__unused id<DVNSplineRendering>)renderer
                   endedWithModel:(DVNSplineRenderModel *)model {
  if (![self.delegate respondsToSelector:@selector(renderingOfPainter:endedWithBrushStroke:)]) {
    return;
  }
  DVNBrushStrokeSpecification *brushStrokeSpecification =
      [DVNBrushStrokeSpecification specificationWithControlPointModel:model.controlPointModel
                                                     brushRenderModel:self.brushRenderModel
                                                          endInterval:model.endInterval];
  [self.delegate renderingOfPainter:self endedWithBrushStroke:brushStrokeSpecification];
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

+ (void)paintBrushStrokesAccordingToData:(NSArray<DVNBrushStrokeData *> *)brushStrokeData
                              ontoCanvas:(LTTexture *)canvas {
  if (!brushStrokeData.count) {
    return;
  }

  DVNBrushRenderConfigurationProvider *provider =
      [[DVNBrushRenderConfigurationProvider alloc] init];

  NSArray<DVNSplineRenderModel *> *models =
      [brushStrokeData lt_map:^DVNSplineRenderModel *(DVNBrushStrokeData *data) {
    DVNPipelineConfiguration *configuration =
        [provider configurationForModel:data.specification.brushRenderModel
                     withTextureMapping:data.textureMapping];
    return [[DVNSplineRenderModel alloc]
            initWithControlPointModel:data.specification.controlPointModel
            configuration:configuration endInterval:data.specification.endInterval];
  }];

  [DVNPainter processModels:models usingCanvas:canvas];
}

#pragma mark -
#pragma mark Proxied Properties
#pragma mark -

- (nullable DVNBrushRenderTargetInformation *)renderTargetInfo {
  return self.brushRenderModel.renderTargetInfo;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (BOOL)currentlyProcessingContentTouchEventSequence {
  return self.renderer != nil;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCurrentlyProcessingContentTouchEventSequence {
  return [NSSet setWithObject:@instanceKeypath(DVNBrushStrokePainter, renderer)];
}

- (LTParameterizedObjectType *)brushSplineType {
  return [self.delegate respondsToSelector:@selector(brushSplineType)] ?
      [self.delegate brushSplineType] : $(LTParameterizedObjectTypeBSpline);
}

@end

NS_ASSUME_NONNULL_END
