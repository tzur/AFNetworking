// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBrush.h"

#import "LTBrushColorDynamicsEffect.h"
#import "LTBrushScatterEffect.h"
#import "LTBrushShapeDynamicsEffect.h"
#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTFbo.h"
#import "LTPainterPoint.h"
#import "LTPainterStrokeSegment.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTRotatedRect+UIColor.h"
#import "LTShaderStorage+LTBrushShaderFsh.h"
#import "LTShaderStorage+LTBrushShaderVsh.h"
#import "LTTexture+Factory.h"
#import "UIColor+Vector.h"

@interface LTBrush ()

/// Texture holding the brush. Cannot be set to \c nil, and default value is a 1x1 texture with
/// maximal intensity.
@property (strong, nonatomic) LTTexture *texture;

/// Shader program used for painting with the brush. The default program is an additive fragment
/// shader that takes the brush's opacity and flow into account.
@property (strong, nonatomic) LTProgram *program;

/// Drawer used for painting with the brush.
@property (strong, nonatomic) LTRectDrawer *drawer;

@end

@implementation LTBrush

static CGSize kDefaultTextureSize = CGSizeMake(1, 1);

#pragma mark -
#pragma mark Initialization.
#pragma mark -

- (instancetype)init {
  if (self = [super init]) {
    [self setBrushDefaults];
    self.texture = [self createTexture];
    self.program = [self createProgram];
    self.drawer = [self createDrawer];
    [self updateProgramForCurrentProperties];
  }
  return self;
}

- (void)setBrushDefaults {
  self.baseDiameter = [LTDevice currentDevice].fingerSizeOnDevice * [UIScreen mainScreen].scale;
  self.flow = self.defaultFlow;
  self.scale = self.defaultScale;
  self.angle = self.defaultAngle;
  self.spacing = self.defaultSpacing;
  self.opacity = self.defaultOpacity;
  self.intensity = self.defaultIntensity;
}

- (LTTexture *)createTexture {
  cv::Mat1b defaultMat(kDefaultTextureSize.height, kDefaultTextureSize.width, 255);
  return [LTTexture textureWithImage:defaultMat];
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushShaderVsh source]
                                  fragmentSource:[LTBrushShaderFsh source]];
}

- (LTRectDrawer *)createDrawer {
  LTAssert(self.texture);
  LTAssert(self.program);
  return [[LTRectDrawer alloc] initWithProgram:self.program sourceTexture:self.texture];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)startNewStrokeAtPoint:(LTPainterPoint __unused *)point {
  [self updateProgramForCurrentProperties];
}

- (LTRotatedRect *)drawPoint:(LTPainterPoint *)point inFramebuffer:(LTFbo *)fbo {
  CGFloat diameter = [self diameterForZoomScale:point.zoomScale];
  LTRotatedRect *sourceRect = [LTRotatedRect rect:CGRectFromSize(self.texture.size)];
  LTRotatedRect *targetRect =
      [LTRotatedRect squareWithCenter:point.contentPosition length:diameter angle:self.angle];
  [self drawRects:@[targetRect] inFramebuffer:fbo fromRects:@[sourceRect]];
  return [self normalizeRect:targetRect forSize:fbo.size];
}

- (NSArray *)drawStrokeSegment:(LTPainterStrokeSegment *)segment
             fromPreviousPoint:(LTPainterPoint *)previousPoint
                 inFramebuffer:(LTFbo *)fbo
          saveLastDrawnPointTo:(LTPainterPoint **)lastDrawnPoint {
  NSArray *points = [self pointsForStrokeSegment:segment fromPreviousPoint:previousPoint];

  NSMutableArray *mutableTargetRects = [NSMutableArray array];
  for (LTPainterPoint *point in points) {
    [mutableTargetRects addObject:[LTRotatedRect squareWithCenter:point.contentPosition
                                                           length:point.diameter angle:self.angle]];
  }
  
  NSArray *targetRects = [self targetRectsWithEffectsFromRects:mutableTargetRects
                                               framebufferSize:fbo.size];
  
  NSMutableArray *sourceRects = [NSMutableArray array];
  for (NSUInteger i = 0; i < targetRects.count; ++i) {
    [sourceRects addObject:[LTRotatedRect rect:CGRectFromSize(self.texture.size)]];
  }
  
  [self drawRects:targetRects inFramebuffer:fbo fromRects:sourceRects];
  if (lastDrawnPoint) {
    *lastDrawnPoint = points.lastObject;
  }
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
      self.program[[LTBrushShaderFsh intensity]] =
          $([(LTRotatedRect *)targetRects[i] color].glkVector);
      [self.drawer drawRotatedRect:targetRects[i] inBoundFramebufferWithSize:fbo.size
                   fromRotatedRect:sourceRects[i]];
    }
  }];
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
                          baseColor:[UIColor colorWithGLKVector:self.intensity]];
    [targetRects enumerateObjectsUsingBlock:^(LTRotatedRect *rect, NSUInteger idx, BOOL *) {
      rect.color = colors[idx];
    }];
  }
  
  return targetRects;
}

- (NSArray *)pointsForStrokeSegment:(LTPainterStrokeSegment *)segment
                  fromPreviousPoint:(LTPainterPoint *)previousPoint {
  CGFloat diameter = [self diameterForZoomScale:segment.zoomScale];
  CGFloat spacing = MAX(diameter * self.spacing, 1.0);
  CGFloat offset = previousPoint ?
      MAX(0, previousPoint.distanceFromStart - segment.distanceFromStart + spacing) : 0;
  
  NSArray *points = [segment pointsWithInterval:spacing startingAtOffset:offset];
  for (LTPainterPoint *point in points) {
    point.diameter = diameter;
  }
  return points;
}

- (CGFloat)diameterForZoomScale:(CGFloat)zoomScale {
  LTParameterAssert(zoomScale > 0);
  return self.baseDiameter * self.scale / zoomScale;
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
  self.program[[LTBrushShaderFsh flow]] = @(self.flow);
  self.program[[LTBrushShaderFsh opacity]] = @(self.opacity);
  self.program[[LTBrushShaderFsh intensity]] = $(self.intensity);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTBoundedPrimitivePropertyImplement(CGFloat, scale, Scale, 0.01, 3.0, 1.0)
LTBoundedPrimitivePropertyImplement(CGFloat, spacing, Spacing, 0.01, 10.0, 0.05)
LTBoundedPrimitivePropertyImplementAndUpdateProgram(CGFloat, opacity, Opacity, 0, 1, 1)
LTBoundedPrimitivePropertyImplementAndUpdateProgram(CGFloat, flow, Flow, 0.01, 1, 1)
LTBoundedPrimitivePropertyImplementWithoutSetter(CGFloat, angle, Angle, 0, 2 * M_PI, 0)
LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector4, intensity, Intensity,
                                                 GLKVector4Make(0, 0, 0, 0),
                                                 GLKVector4Make(1, 1, 1, 1),
                                                 GLKVector4Make(1, 1, 1, 1));

- (void)setAngle:(CGFloat)angle {
  angle = std::fmod(angle, 2 * M_PI);
  _angle = angle + ((angle < 0) ? 2 * M_PI : 0);
}

- (void)setIntensity:(GLKVector4)intensity {
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(intensity, self.minIntensity));
  LTParameterAssert(GLKVector4AllGreaterThanOrEqualToVector4(self.maxIntensity, intensity));
  _intensity = intensity;
  [self updateProgramForCurrentProperties];
}

- (void)setTexture:(LTTexture *)texture {
  LTParameterAssert(texture.format == LTTextureFormatRed);
  _texture = texture;
  [self.drawer setSourceTexture:texture];
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"angle", @"spacing", @"opacity", @"flow"];
}

@end
