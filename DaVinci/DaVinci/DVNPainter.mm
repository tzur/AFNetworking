// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNPainter.h"

#import <LTEngine/LTFbo.h>
#import <LTEngine/LTFboPool.h>
#import <LTEngine/LTTexture.h>

#import "DVNBrushRenderInfoProvider.h"
#import "DVNSplineRenderer.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNPainter () <DVNSplineRenderingDelegate>

/// Texture onto which to render.
@property (readonly, nonatomic) LTTexture *texture;

/// Framebuffer used to render onto the \c texture.
@property (readonly, nonatomic) LTFbo *fbo;

/// Provider of spline rendering information.
@property (weak, readonly, nonatomic) id<DVNBrushRenderInfoProvider> renderInfoProvider;

/// Renderer used to render onto the \c texture. Is not \c nil only during a process sequence.
@property (strong, nonatomic, nullable) DVNSplineRenderer *renderer;

@end

@implementation DVNPainter

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithCanvas:(LTTexture *)canvas
       brushRenderInfoProvider:(id<DVNBrushRenderInfoProvider>)brushRenderInfoProvider
                      delegate:(nullable id<DVNPainterDelegate>)delegate {
  LTParameterAssert(canvas);
  LTParameterAssert(brushRenderInfoProvider);

  if (self = [super init]) {
    _texture = canvas;
    _fbo = [[LTFboPool currentPool] fboWithTexture:canvas];
    _renderInfoProvider = brushRenderInfoProvider;
    _delegate = delegate;
  }
  return self;
}

#pragma mark -
#pragma mark DVNSplineRendering
#pragma mark -

- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end {
  if (!self.currentlyProcessingContentTouchEventSequence) {
    [self createRenderer];
  }

  LTAssert(self.renderer, @"Spline renderer must exist at this point");

  [self.fbo bindAndDraw:^{
    [self.renderer processControlPoints:controlPoints end:end];
  }];

  if (end) {
    self.renderer = nil;
  }
}

- (void)createRenderer {
  LTAssert(self.renderInfoProvider,
           @"Render info provider deallocated before start of new process sequence");
  LTAssert(!self.renderer, @"Spline renderer must not exist at this point");
  LTParameterizedObjectType *type = [self.renderInfoProvider brushSplineType];
  DVNPipelineConfiguration *pipelineConfiguration =
      [self.renderInfoProvider brushRenderConfiguration];
  self.renderer = [[DVNSplineRenderer alloc] initWithType:type configuration:pipelineConfiguration
                                                 delegate:self];
}

- (void)cancel {
  [self.renderer cancel];
  self.renderer = nil;
}

+ (void)processModels:(NSArray<DVNSplineRenderModel *> *)models
          usingCanvas:(LTTexture *)canvas {
  LTFbo *fbo = [[LTFboPool currentPool] fboWithTexture:canvas];
  [fbo bindAndDraw:^{
    for (DVNSplineRenderModel *model in models) {
      @autoreleasepool {
        [DVNSplineRenderer processModel:model];
      }
    }
  }];
}

#pragma mark -
#pragma mark DVNSplineRenderingDelegate
#pragma mark -

- (void)renderingOfSplineRendererWillStart:(id<DVNSplineRendering>)renderer {
  [self validateRenderer:renderer];
  if ([self.delegate respondsToSelector:@selector(renderingOfSplineRendererWillStart:)]) {
    [self.delegate renderingOfSplineRendererWillStart:self];
  }
}

- (void)validateRenderer:(DVNSplineRenderer *)renderer {
  LTParameterAssert(self.renderer == renderer, @"Provided renderer (%@) different than maintained "
                    "renderer (%@)", renderer, self.renderer);
}

- (void)renderingOfSplineRenderer:(id<DVNSplineRendering>)renderer
               continuedWithQuads:(const std::vector<lt::Quad> &)quads {
  [self validateRenderer:renderer];
  if ([self.delegate respondsToSelector:@selector(renderingOfSplineRenderer:continuedWithQuads:)]) {
    [self.delegate renderingOfSplineRenderer:self continuedWithQuads:quads];
  }
}

- (void)renderingOfSplineRenderer:(id<DVNSplineRendering>)renderer
                   endedWithModel:(DVNSplineRenderModel *)model {
  [self validateRenderer:renderer];
  if ([self.delegate respondsToSelector:@selector(renderingOfSplineRenderer:endedWithModel:)]) {
    [self.delegate renderingOfSplineRenderer:self endedWithModel:model];
  }
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)clearCanvasWithColor:(LTVector4)color {
  if (!self.currentlyProcessingContentTouchEventSequence) {
    [self.texture clearColor:color];
    if ([self.delegate respondsToSelector:@selector(painter:clearedCanvasWithColor:)]) {
      [self.delegate painter:self clearedCanvasWithColor:color];
    }
  }
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (BOOL)currentlyProcessingContentTouchEventSequence {
  return self.renderer != nil;
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingCurrentlyProcessingContentTouchEventSequence {
  return [NSSet setWithObject:@instanceKeypath(DVNPainter, renderer)];
}

@end

NS_ASSUME_NONNULL_END
