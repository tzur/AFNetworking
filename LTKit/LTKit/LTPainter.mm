// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter.h"

#import "LTCatmullRomInterpolationRoutine.h"
#import "LTCGExtensions.h"
#import "LTErasingBrush.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTPainterStroke.h"
#import "LTPainterStrokeSegment.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTRotatedRect.h"
#import "LTRoundBrush.h"
#import "LTShaderStorage+LTPainterMergeShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"
#import "LTTouchCollector.h"
#import "LTTouchCollectorDistanceFilter.h"
#import "LTTouchCollectorTimeIntervalFilter.h"

@interface LTPainter () <LTTouchCollectorDelegate>

/// Target mode for the painter, see \c LTPainterTargetMode.
@property (nonatomic) LTPainterTargetMode mode;

/// Texture being painted on.
@property (strong, nonatomic) LTTexture *canvasTexture;

/// Temporary texture holding the currently active storke, Used only when the target mode is
/// \c LTPainterTargetModeSandboxedStroke. Otherwise, a 1x1 zero texture is returned.
@property (strong, nonatomic) LTTexture *strokeTexture;

/// Framebuffer used for drawing over the canvas texture.
@property (strong, nonatomic) LTFbo *canvasFbo;

/// Framebuffer used for drawing over the stroke texture.
@property (strong, nonatomic) LTFbo *strokeFbo;

/// Drawer used to merge the current stroke with the canvas stroke.
@property (strong, nonatomic) LTRectDrawer *strokeDrawer;

/// Touch collector used for receiving touch events from an \c LTView.
@property (strong, nonatomic) LTTouchCollector *touchCollector;

/// Array of \c LTPainterStrokes, containing all the previous strokes, excluding the currently
/// active one.
@property (strong, nonatomic) NSMutableArray *mutableStrokes;

/// Currently active stroke.
@property (strong, nonatomic) LTPainterStroke *currentStroke;

/// Last point that was actually painted (not necessarily the ending point of the last segment).
@property (strong, nonatomic) LTPainterPoint *lastDrawnPoint;

@end

@implementation LTPainter

#pragma mark -
#pragma mark Initilization
#pragma mark -

- (instancetype)initWithMode:(LTPainterTargetMode)mode canvas:(LTTexture *)canvas {
  if (self = [super init]) {
    LTParameterAssert(canvas);
    self.mode = mode;
    self.canvasTexture = canvas;
    [self createStrokeTexture];
    [self createStrokeDrawer];
    [self createFbos];
    [self createTouchCollector];
    [self createDefaultConfiguration];
  }
  return self;
}

- (void)createStrokeTexture {
  if (self.mode == LTPainterTargetModeSandboxedStroke) {
    self.strokeTexture = [LTTexture textureWithPropertiesOf:self.canvasTexture];
  } else {
    self.strokeTexture = [LTTexture textureWithSize:CGSizeMakeUniform(1)
                                          precision:self.canvasTexture.precision
                                             format:self.canvasTexture.format allocateMemory:YES];
  }
  self.strokeTexture.minFilterInterpolation = LTTextureInterpolationNearest;
  self.strokeTexture.magFilterInterpolation = LTTextureInterpolationNearest;
}

- (void)createStrokeDrawer {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                                                fragmentSource:[LTPainterMergeShaderFsh source]];
  self.strokeDrawer = [[LTRectDrawer alloc] initWithProgram:program
                                              sourceTexture:self.strokeTexture];
}

- (void)createFbos {
  self.canvasFbo = [[LTFbo alloc] initWithTexture:self.canvasTexture];
  self.strokeFbo = [[LTFbo alloc] initWithTexture:self.strokeTexture];
  [self.strokeFbo clearWithColor:GLKVector4Make(0, 0, 0, 0)];
}

- (void)createTouchCollector {
  LTTouchCollector *collector = [[LTTouchCollector alloc] init];
  collector.delegate = self;
  self.touchCollector = collector;
}

- (void)createDefaultConfiguration {
  self.brush = [self createDefaultBrush];
  self.splineFactory= [self createDefaultSplineFactory];
  self.touchCollector.filter = [self createDefaultTouchCollectorFilter];
}

- (LTBrush *)createDefaultBrush {
  LTRoundBrush *brush = [[LTRoundBrush alloc] init];
  return brush;
}

- (id<LTInterpolationRoutineFactory>)createDefaultSplineFactory {
  return [[LTCatmullRomInterpolationRoutineFactory alloc] init];
}

- (id<LTTouchCollectorFilter>)createDefaultTouchCollectorFilter {
  return [[LTTouchCollectorOrFilter alloc] initWithFilters:@[
             [LTTouchCollectorTimeIntervalFilter filterWithMinimalTimeInterval:0.3],
             [LTTouchCollectorDistanceFilter filterWithMinimalScreenDistance:5]]];
}

#pragma mark -
#pragma mark LTTouchCollectorDelegate
#pragma mark -

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
         startedStrokeAt:(LTPainterPoint *)touch {
  LTAssert(!self.currentStroke, @"started a stroke, but stroke is already in progress");
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  [self startStrokeAt:point];
}

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
    collectedStrokeTouch:(LTPainterPoint *)touch {
  LTAssert(self.currentStroke, @"collected stroke touch, but no stroke in progress");
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  LTPainterStrokeSegment *segment = [self.currentStroke addSegmentTo:point];
  if (segment) {
    LTPainterPoint *lastDrawnPoint;
    NSArray *paintedRects = [self.brush drawStrokeSegment:segment
                                        fromPreviousPoint:self.lastDrawnPoint
                                            inFramebuffer:self.fboForPainting
                                     saveLastDrawnPointTo:&lastDrawnPoint];
    self.lastDrawnPoint = lastDrawnPoint ?: self.lastDrawnPoint;
    if (paintedRects.count) {
      [self.delegate ltPainter:self didPaintInRotatedRects:paintedRects];
    }
  }
}

- (void)ltTouchCollector:(LTTouchCollector __unused *)touchCollector
     collectedTimerTouch:(LTPainterPoint *)touch {
  LTAssert(self.currentStroke, @"collected timer touch, but no stroke in progress");
  LTPainterPoint *point = [self pointForTargetCoordinateSystem:touch];
  if (!self.airbrush) {
    return;
  }
  
  point.distanceFromStart = self.lastDrawnPoint.distanceFromStart +
      CGPointDistance(point.contentPosition, self.lastDrawnPoint.contentPosition);
  
  [self.currentStroke addPointAt:point];
  LTRotatedRect *paintedRect = [self.brush drawPoint:point inFramebuffer:self.fboForPainting];
  self.lastDrawnPoint = point;
  [self.delegate ltPainter:self didPaintInRotatedRects:@[paintedRect]];
}

- (void)ltTouchCollectorFinishedStroke:(LTTouchCollector __unused *)touchCollector
                             cancelled:(BOOL)cancelled {
  LTAssert(self.currentStroke, @"finished a stroke, but no stroke in progress");
  // Identify a tap gesture and draw a point for it.
  if (!cancelled && !self.lastDrawnPoint) {
    LTRotatedRect *paintedRect = [self.brush drawPoint:self.currentStroke.startingPoint
                                         inFramebuffer:self.fboForPainting];
    [self.delegate ltPainter:self didPaintInRotatedRects:@[paintedRect]];
  }
  [self endStroke];
}

/// Returns a copy of the given point, after applying the alternative coordinate system transform
/// (if available) on its contentPosition, and replacing its zoomScale (if available).
- (LTPainterPoint *)pointForTargetCoordinateSystem:(LTPainterPoint *)point {
  LTPainterPoint *newPoint = [point copy];
  if ([self.delegate respondsToSelector:@selector(alternativeCoordinateSystemTransform)]) {
    newPoint.contentPosition =
        CGPointApplyAffineTransform(newPoint.contentPosition,
                                    [self.delegate alternativeCoordinateSystemTransform]);
  }
  if ([self.delegate respondsToSelector:@selector(alternativeZoomScale)]) {
    newPoint.zoomScale = [self.delegate alternativeZoomScale];
  }
  return newPoint;
}

#pragma mark -
#pragma mark Painting
#pragma mark -

- (void)startStrokeAt:(LTPainterPoint *)point {
  self.currentStroke = [[LTPainterStroke alloc]
                        initWithInterpolationRoutineFactory:self.splineFactory
                        startingPoint:point];
  [self.brush startNewStrokeAtPoint:point];
}

- (void)endStroke {
  [self.mutableStrokes addObject:self.currentStroke];
  self.lastDrawnPoint = nil;
  self.currentStroke = nil;
  if (self.mode == LTPainterTargetModeSandboxedStroke) {
    [self mergeStrokeCanvasWithPainterCanvas];
  }
  if ([self.delegate respondsToSelector:@selector(ltPainter:didFinishStroke:)]) {
    [self.delegate ltPainter:self didFinishStroke:self.mutableStrokes.lastObject];
  }
}

- (void)mergeStrokeCanvasWithPainterCanvas {
  [self.strokeDrawer drawRect:CGRectFromSize(self.canvasFbo.size) inFramebuffer:self.canvasFbo
                     fromRect:CGRectFromSize(self.strokeTexture.size)];
  [self.strokeFbo clearWithColor:GLKVector4Make(0, 0, 0, 0)];
}

- (void)clearWithColor:(GLKVector4)color {
  [self.canvasFbo clearWithColor:color];
}

- (void)paintStroke:(LTPainterStroke *)stroke {
  LTParameterAssert(stroke);
  LTPainterPoint *lastDrawnPoint;
  for (id segment in stroke.segments) {
    if ([segment isKindOfClass:[LTPainterPoint class]]) {
      [self.brush drawPoint:segment inFramebuffer:self.canvasFbo];
      lastDrawnPoint = segment;
    } else if ([segment isKindOfClass:[LTPainterStrokeSegment class]]) {
      [self.brush drawStrokeSegment:segment fromPreviousPoint:lastDrawnPoint
                      inFramebuffer:self.canvasFbo
               saveLastDrawnPointTo:&lastDrawnPoint];
    } else {
      LTAssert(NO, @"Unsupported segment type");
    }
  }
}

- (BOOL)isErasingBrush:(LTBrush *)brush {
  return [brush isKindOfClass:[LTErasingBrush class]];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (id<LTViewTouchDelegate>)touchDelegateForLTView {
  return self.touchCollector;
}

- (NSMutableArray *)mutableStrokes {
  if (!_mutableStrokes) {
    _mutableStrokes = [NSMutableArray array];
  }
  return _mutableStrokes;
}

- (NSArray *)strokes {
  return [self.mutableStrokes copy];
}

- (LTFbo *)fboForPainting {
  return self.mode == LTPainterTargetModeSandboxedStroke ? self.strokeFbo : self.canvasFbo;
}

@end
