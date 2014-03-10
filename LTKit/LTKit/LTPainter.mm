// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPainter.h"

#import "LTCatmullRomInterpolationRoutine.h"
#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTGLKitExtensions.h"
#import "LTPainterPoint.h"
#import "LTPainterStroke.h"
#import "LTPainterStrokeSegment.h"
#import "LTProgram.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTRoundBrush.h"
#import "LTShaderStorage+LTPainterMergeShaderFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@interface LTPainter ()

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

/// Array of \c LTPainterStrokes, containing all the previous strokes, excluding the currently
/// active one.
@property (strong, nonatomic) NSMutableArray *mutableStrokes;

@end

@implementation LTPainter

#pragma mark -
#pragma mark Initilization
#pragma mark -

- (instancetype)initWithMode:(LTPainterTargetMode)mode canvasTexture:(LTTexture *)canvasTexture {
  if (self = [super init]) {
    LTParameterAssert(canvasTexture);
    self.mode = mode;
    self.canvasTexture = canvasTexture;
    [self createStrokeTexture];
    [self createStrokeDrawer];
    [self createFbos];
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

- (void)createDefaultConfiguration {
  self.brush = [self createDefaultBrush];
  self.splineFactory = [self createDefaultSplineFactory];
}

- (LTBrush *)createDefaultBrush {
  return [[LTRoundBrush alloc] init];
}

- (id<LTInterpolationRoutineFactory>)createDefaultSplineFactory {
  return [[LTCatmullRomInterpolationRoutineFactory alloc] init];
}

#pragma mark -
#pragma mark Painting
#pragma mark -

- (void)mergeStrokeCanvasWithPainterCanvasIfNecessary {
  if (self.mode == LTPainterTargetModeSandboxedStroke) {
    [self.strokeDrawer drawRect:CGRectFromSize(self.canvasFbo.size) inFramebuffer:self.canvasFbo
                       fromRect:CGRectFromSize(self.strokeTexture.size)];
    [self.strokeFbo clearWithColor:GLKVector4Make(0, 0, 0, 0)];
  }
}

- (void)clearWithColor:(GLKVector4)color {
  [self.canvasFbo clearWithColor:color];
  [self.mutableStrokes removeAllObjects];
}

- (void)paintStroke:(LTPainterStroke *)stroke {
  LTParameterAssert(stroke);
  if (!stroke.segments.count) {
    return;
  }
  
  LTPainterPoint *lastDrawnPoint;
  for (id segment in stroke.segments) {
    if ([segment isKindOfClass:[LTPainterPoint class]]) {
      [self.brush drawPoint:segment inFramebuffer:self.fboForPainting];
      lastDrawnPoint = segment;
    } else if ([segment isKindOfClass:[LTPainterStrokeSegment class]]) {
      [self.brush drawStrokeSegment:segment fromPreviousPoint:lastDrawnPoint
                      inFramebuffer:self.fboForPainting
               saveLastDrawnPointTo:&lastDrawnPoint];
    } else {
      LTAssert(NO, @"Unsupported segment type");
    }
  }

  [self mergeStrokeCanvasWithPainterCanvasIfNecessary];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

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
