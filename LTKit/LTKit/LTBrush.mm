// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

#import "LTBrushColorDynamicsEffect.h"
#import "LTBrushRandomState.h"
#import "LTBrushScatterEffect.h"
#import "LTBrushShapeDynamicsEffect.h"
#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTGLKitExtensions.h"
#import "LTKeyPathCoding.h"
#import "LTPainterPoint.h"
#import "LTPainterStrokeSegment.h"
#import "LTProgram.h"
#import "LTRandom.h"
#import "LTRectDrawer.h"
#import "LTRotatedRect+UIColor.h"
#import "LTShaderStorage+LTBrushFsh.h"
#import "LTShaderStorage+LTBrushVsh.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

@interface LTBrush ()

/// The random generator used by the effect.
@property (strong, nonatomic) LTRandom *random;

/// Texture holding the brush. Cannot be set to \c nil, and default value is a 1x1 texture with
/// maximal intensity.
@property (strong, nonatomic) LTTexture *texture;

/// Shader program used for painting with the brush. The default program is an additive fragment
/// shader that takes the brush's opacity and flow into account.
@property (strong, nonatomic) LTProgram *program;

/// Drawer used for painting with the brush.
@property (strong, nonatomic) LTRectDrawer *drawer;

/// Point to use to determine the dynamic scale that should be applied to the brush, in case
/// \c consistentScaleDuringStroke is \c YES.
@property (nonatomic) LTPainterPoint *pointForConsistentScale;

@end

@implementation LTBrush

static CGSize kDefaultTextureSize = CGSizeMake(1, 1);

/// Minimum actual diameter (in pixels) of the brush. trying to draw rects smaller than 2x2 pixels
/// may lead to discontinuity of the stroke.
static const CGFloat kMinimumDiameter = 2;

#pragma mark -
#pragma mark Initialization.
#pragma mark -

- (instancetype)init {
  return [self initWithRandom:[JSObjection defaultInjector][[LTRandom class]]];
}

- (instancetype)initWithRandom:(LTRandom *)random {
  LTParameterAssert(random);
  if (self = [super init]) {
    [self setBrushDefaults];
    self.random = random;
    self.texture = [self createTexture];
    self.program = [self createProgram];
    self.drawer = [self createDrawer];
    [self updateProgramForCurrentProperties];
  }
  return self;
}

- (void)setBrushDefaults {
  self.baseDiameter = [LTDevice currentDevice].fingerSizeOnDevice *
                      [LTDevice currentDevice].glkContentScaleFactor;
}

- (LTTexture *)createTexture {
  cv::Mat1b defaultMat(kDefaultTextureSize.height, kDefaultTextureSize.width, 255);
  return [LTTexture textureWithImage:defaultMat];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushVsh source]
                                  fragmentSource:[LTBrushFsh source]];
}

- (LTRectDrawer *)createDrawer {
  LTAssert(self.texture);
  LTAssert(self.program);
  return [[LTRectDrawer alloc] initWithProgram:self.program sourceTexture:self.texture];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)startNewStrokeAtPoint:(LTPainterPoint *)point {
  if (self.randomAnglePerStroke) {
    self.angle = [self.random randomDoubleBetweenMin:0 max:2 * M_PI];
  }
  if (self.forceConsistentScaleDuringStroke) {
    self.pointForConsistentScale = point;
  }
  [self updateProgramForCurrentProperties];
}

- (NSArray *)drawPoint:(LTPainterPoint *)point inFramebuffer:(LTFbo *)fbo {
  CGFloat diameter = [self diameterForPoint:point];
  LTRotatedRect *targetRect =
      [LTRotatedRect squareWithCenter:point.contentPosition length:diameter angle:self.angle];
  return [self applyEffectsAndDrawRects:@[targetRect] inFramebuffer:fbo];
}

- (NSArray *)drawStrokeSegment:(LTPainterStrokeSegment *)segment
             fromPreviousPoint:(LTPainterPoint *)previousPoint
                 inFramebuffer:(LTFbo *)fbo
          saveLastDrawnPointTo:(LTPainterPoint *__autoreleasing *)lastDrawnPoint {
  NSArray *points = [self pointsForStrokeSegment:segment fromPreviousPoint:previousPoint];
  if (lastDrawnPoint) {
    *lastDrawnPoint = points.lastObject;
  }

  NSMutableArray *mutableTargetRects = [NSMutableArray array];
  for (LTPainterPoint *point in points) {
    [mutableTargetRects addObject:[LTRotatedRect squareWithCenter:point.contentPosition
                                                           length:point.diameter angle:self.angle]];
  }
  return [self applyEffectsAndDrawRects:mutableTargetRects inFramebuffer:fbo];
}

- (NSArray *)applyEffectsAndDrawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo {
  targetRects = [self targetRectsWithEffectsFromRects:targetRects framebufferSize:fbo.size];
  NSArray *sourceRects = [self sourceRectsWithCount:targetRects.count];
  [self drawRects:targetRects inFramebuffer:fbo fromRects:sourceRects];
  return [self normalizedRects:targetRects forSize:fbo.size];
}

/// Draws the given source rects on the given target rects in the framebuffer.
///
/// @note This method allows subclasses to replace the drawing mechanism, or perform things before
/// the actual draw.
- (void)drawRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
        fromRects:(NSArray *)sourceRects {
  if (self.texture && targetRects.count) {
    if ([(LTRotatedRect *)targetRects.firstObject color]) {
      [self drawColoredRects:targetRects inFramebuffer:fbo fromRects:sourceRects];
    } else {
      [self.drawer drawRotatedRects:targetRects inFramebuffer:fbo fromRotatedRects:sourceRects];
    }
  }
}

- (void)drawColoredRects:(NSArray *)targetRects inFramebuffer:(LTFbo *)fbo
               fromRects:(NSArray *)sourceRects {
  LTParameterAssert(targetRects.count == sourceRects.count);
  [fbo bindAndDraw:^{
    for (NSUInteger i = 0; i < targetRects.count; ++i) {
      self.program[[LTBrushFsh intensity]] = $([(LTRotatedRect *)targetRects[i] color].lt_ltVector);
      [self.drawer drawRotatedRect:targetRects[i] inFramebufferWithSize:fbo.size
                   fromRotatedRect:sourceRects[i]];
    }
  }];
}

- (NSArray *)sourceRectsWithCount:(NSUInteger)count {
  NSMutableArray *sourceRects = [NSMutableArray arrayWithCapacity:count];
  for (NSUInteger i = 0; i < count; ++i) {
    [sourceRects addObject:[LTRotatedRect rect:CGRectFromSize(self.texture.size)]];
  }
  return sourceRects;
}

- (NSArray *)targetRectsWithEffectsFromRects:(NSArray *)targetRects framebufferSize:(CGSize)size {
  if (self.scatterEffect) {
    targetRects = [self.scatterEffect scatteredRectsFromRects:targetRects];
  }
  if (self.shapeDynamicsEffect) {
    targetRects = [self.shapeDynamicsEffect dynamicRectsFromRects:targetRects];
  }
  if (self.colorDynamicsEffect) {
    NSArray *normalizedRects = [self normalizedRects:targetRects forSize:size];
    NSArray *colors = [self.colorDynamicsEffect colorsFromRects:normalizedRects
                          baseColor:[UIColor lt_colorWithLTVector:self.intensity]];
    [targetRects enumerateObjectsUsingBlock:^(LTRotatedRect *rect, NSUInteger idx, BOOL *) {
      rect.color = colors[idx];
    }];
  }
  
  return targetRects;
}

- (NSArray *)pointsForStrokeSegment:(LTPainterStrokeSegment *)segment
                  fromPreviousPoint:(LTPainterPoint *)previousPoint {
  CGFloat diameter = [self diameterForStrokeSegment:segment];
  CGFloat spacing = MAX(diameter * self.spacing, 1.0);
  CGFloat offset = previousPoint ?
      MAX(0, previousPoint.distanceFromStart - segment.distanceFromStart + spacing) : 0;
  
  NSArray *points = [segment pointsWithInterval:spacing startingAtOffset:offset];
  for (LTPainterPoint *point in points) {
    point.diameter = diameter;
  }
  return points;
}

- (CGFloat)diameterForStrokeSegment:(LTPainterStrokeSegment *)segment {
  LTPainterPoint *point = self.forceConsistentScaleDuringStroke && self.pointForConsistentScale ?
      self.pointForConsistentScale : segment.startPoint;

  return [self diameterForPoint:point];
}

- (CGFloat)diameterForPoint:(LTPainterPoint *)point {
  CGFloat pointScaleFactor = [self scaleFactorForPoint:point];
  return MAX(self.baseDiameter * self.scale * pointScaleFactor, kMinimumDiameter);
}

- (CGFloat)scaleFactorForPoint:(LTPainterPoint *)point {
  LTParameterAssert(point.zoomScale > 0);
  return [self touchScaleFactorForPoint:point] / point.zoomScale;
}

- (CGFloat)touchScaleFactorForPoint:(LTPainterPoint *)point {
  if (!self.touchRadiusMapper) {
    return 1;
  }

  return [self.touchRadiusMapper scaleForTouchRadius:point.touchRadius
                                           tolerance:point.touchRadiusTolerance];
}

- (NSArray *)normalizedRects:(NSArray *)rects forSize:(CGSize)size {
  NSMutableArray *normalizedRects = [NSMutableArray array];
  for (LTRotatedRect *rect in rects) {
    [normalizedRects addObject:[self normalizeRect:rect forSize:size]];
  }
  return normalizedRects;
}

- (LTRotatedRect *)normalizeRect:(LTRotatedRect *)rotatedRect forSize:(CGSize)size {
  return [LTRotatedRect rectWithCenter:rotatedRect.center / size
                                  size:rotatedRect.rect.size / size
                                 angle:self.angle];
}

- (void)updateProgramForCurrentProperties {
  self.program[[LTBrushFsh flow]] = @(self.flow);
  self.program[[LTBrushFsh opacity]] = @(self.opacity);
  self.program[[LTBrushFsh intensity]] = $(self.intensity);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTProperty(CGFloat, scale, Scale, 0.01, 3.0, 1.0)
LTProperty(CGFloat, spacing, Spacing, 0.01, 10.0, 0.05)
LTPropertyUpdatingProgram(CGFloat, opacity, Opacity, 0, 1, 1)
LTPropertyUpdatingProgram(CGFloat, flow, Flow, 0.01, 1, 1)
LTPropertyUpdatingProgram(LTVector4, intensity, Intensity,
                          LTVector4Zero, LTVector4One, LTVector4One);

LTPropertyWithoutSetter(CGFloat, angle, Angle, 0, 2 * M_PI, 0);
- (void)setAngle:(CGFloat)angle {
  angle = std::fmod(angle, 2 * M_PI);
  angle = angle + ((angle < 0) ? 2 * M_PI : 0);
  [self _verifyAndSetAngle:angle];
}

- (LTBrushRandomState *)randomState {
  NSMutableDictionary *randomStates = [NSMutableDictionary dictionary];
  for (NSString *keyPath in [[self class] keyPathsForRandomState]) {
    LTRandom *random = [self valueForKeyPath:keyPath];
    if (random) {
      LTAssert([random isKindOfClass:[LTRandom class]]);
      randomStates[keyPath] = [random engineState];
    }
  }

  return [[LTBrushRandomState alloc] initWithStates:randomStates];
}

- (void)setRandomState:(LTBrushRandomState *)randomState {
  [randomState.states enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath,
                                                          LTRandomState *randomState, BOOL *) {
    LTParameterAssert([keyPath isKindOfClass:[NSString class]]);
    LTRandom *random = [self valueForKeyPath:keyPath];
    LTParameterAssert(!random || [random isKindOfClass:[LTRandom class]]);
    LTParameterAssert([randomState isKindOfClass:[LTRandomState class]]);

    [random resetToState:randomState];
  }];
}

- (void)setTexture:(LTTexture *)texture {
  LTParameterAssert(texture.format == LTTextureFormatRed);
  _texture = texture;
  [self.drawer setSourceTexture:texture];
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"angle", @"spacing", @"opacity", @"flow"];
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

+ (NSSet *)keyPathsForRandomState {
  return [NSSet setWithArray:@[
    @instanceKeypath(LTBrush, random),
    @instanceKeypath(LTBrush, colorDynamicsEffect.random),
    @instanceKeypath(LTBrush, scatterEffect.random),
    @instanceKeypath(LTBrush, shapeDynamicsEffect.random)
  ]];
}

@end
