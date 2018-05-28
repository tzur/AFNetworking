// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushStrokePainter.h"

#import <LTEngine/LTFbo.h>
#import <LTEngine/LTFboPool.h>
#import <LTEngine/LTParameterizedObjectType.h>
#import <LTEngine/LTTexture.h>
#import <LTKit/LTRandom.h>
#import <LTKit/NSArray+Functional.h>

#import "DVNBrushModel.h"
#import "DVNBrushRenderConfigurationProvider.h"
#import "DVNBrushRenderModel.h"
#import "DVNBrushRenderTargetInformation.h"
#import "DVNBrushStroke.h"
#import "DVNPainter.h"
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

@end

@implementation DVNBrushStrokePainter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithDelegate:(id<DVNBrushStrokePainterDelegate>)delegate {
  LTParameterAssert(delegate);

  if (self = [super init]) {
    _delegate = delegate;
    _provider = [[DVNBrushRenderConfigurationProvider alloc] init];
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

  LTAssert(self.renderer);

  LTTexture * _Nullable canvas = [self.delegate brushStrokeCanvas];

  if (canvas) {
    [self validateCanvas:canvas];

    [[[LTFboPool currentPool] fboWithTexture:canvas] bindAndDraw:^{
      [self.renderer processControlPoints:controlPoints end:end];
    }];
  } else {
    [self.renderer processControlPoints:controlPoints end:end];
  }

  if (end) {
    self.renderer = nil;
    self.brushRenderModel = nil;
  }
}

- (void)cancel {
  [self.renderer cancel];
  self.renderer = nil;
  self.brushRenderModel = nil;
}

#pragma mark -
#pragma mark DVNSplineRendering - Auxiliary Methods
#pragma mark -

- (void)createRenderer {
  LTAssert(!self.renderer);
  LTAssert(!self.brushRenderModel);

  LTParameterizedObjectType *type = [self.delegate respondsToSelector:@selector(brushSplineType)] ?
      [self.delegate brushSplineType] : $(LTParameterizedObjectTypeBSpline);

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

@end

NS_ASSUME_NONNULL_END
