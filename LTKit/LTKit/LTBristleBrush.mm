// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBristleBrush.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTRandom.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

/// A pair of \c CGFloats.
typedef std::pair<CGFloat, CGFloat> CGFloatPair;

@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

@interface LTBristleBrush ()

/// Indicates that the brush should be updated before drawing.
@property (nonatomic) BOOL shouldUpdateBrush;

/// Fbos used for updating the different mipmap levels of the brush texture.
@property (strong, nonatomic) NSArray *brushFbos;

/// Drawer used to draw the bristles when updating the brush texture.
@property (strong, nonatomic) LTRectDrawer *bristleDrawer;

@end

@implementation LTBristleBrush

/// Size (in pixels) of the brush texture on the base level.
static const uint kBaseLevelDiameter = 256;

/// Diameter for the bristle texture.
static const uint kBristleDiameter = 64;

/// Sigma of the gaussian representing each bristle.
static const CGFloat kBristleSigma = 0.4;

- (instancetype)initWithRandom:(LTRandom *)random {
  if (self = [super initWithRandom:random]) {
    [self setBristleBrushDefaults];
    self.brushFbos = [self createBrushFbos];
    self.bristleDrawer = [self createBristleDrawer];
  }
  return self;
}

- (void)setBristleBrushDefaults {
  self.shape = LTBristleBrushShapeRoundBlunt;
  self.bristles = self.defaultBristles;
  self.thickness = self.defaultThickness;
}

- (LTTexture *)createTexture {
  Matrices levels;
  for (uint diameter = kBaseLevelDiameter; diameter > 0; diameter /= 2) {
    levels.push_back(cv::Mat1hf(diameter, diameter));
  }

  LTTexture *texture = [LTTexture textureWithMipmapImages:levels];
  texture.minFilterInterpolation = LTTextureInterpolationLinearMipmapLinear;
  texture.magFilterInterpolation = LTTextureInterpolationLinear;
  return texture;
}

- (NSArray *)createBrushFbos {
  NSMutableArray *fbos = [NSMutableArray array];
  for (GLint i = 0; i < self.texture.maxMipmapLevel; ++i) {
    [fbos addObject:[[LTFbo alloc] initWithTexture:self.texture level:i]];
  }
  return fbos;
}

- (LTRectDrawer *)createBristleDrawer {
  Matrices levels;
  for (uint diameter = kBristleDiameter; diameter > 0; diameter /= 2) {
    cv::Mat1hf gaussian = LTCreateGaussianMat(CGSizeMakeUniform(diameter), kBristleSigma, YES);
    cv::Mat4hf level(gaussian.size());
    cv::Mat channels[] = {gaussian, gaussian, gaussian, gaussian};
    cv::merge(channels, 4, level);
    levels.push_back(level);
  }
  LTTexture *gaussian = [LTTexture textureWithMipmapImages:levels];
  gaussian.minFilterInterpolation = LTTextureInterpolationLinearMipmapLinear;
  gaussian.magFilterInterpolation = LTTextureInterpolationLinear;
  return [[LTRectDrawer alloc] initWithSourceTexture:gaussian];
}

#pragma mark -
#pragma mark Drawing
#pragma mark -

- (void)startNewStrokeAtPoint:(LTPainterPoint *)point {
  [super startNewStrokeAtPoint:point];
  if (self.shouldUpdateBrush) {
    [self updateBrushForCurrentProperties];
  }
}

- (void)updateBrushForCurrentProperties {
  self.shouldUpdateBrush = NO;

  NSArray *bristles = [self bristlesForCurrentProperties];
  NSMutableArray *sources = [NSMutableArray array];
  for (NSUInteger i = 0; i < bristles.count; ++i) {
    [sources addObject:[LTRotatedRect rect:CGRectFromSize(CGSizeMakeUniform(kBristleDiameter))]];
  }

  [[LTGLContext currentContext] executeAndPreserveState:^(LTGLContext *context) {
    context.blendEnabled = YES;
    context.blendFunc = kLTGLContextBlendFuncNormal;
    for (LTFbo *fbo in self.brushFbos) {
      [fbo clearWithColor:LTVector4(0, 0, 0, 1)];
      [self.bristleDrawer drawRotatedRects:bristles inFramebuffer:fbo
                          fromRotatedRects:sources];
    }
  }];
}

// TODO:(amit) implement a better mechanism that avoids collisions and takes the shape into account.
- (NSArray *)bristlesForCurrentProperties {
  // We're using a contant seed since we prefer something pseudo-random, that will generate the same
  // brush under the same parameters. This is important so users can duplicate a previous result.
  static const NSUInteger kRandomSeed = 100;
  LTRandom *random = [[LTRandom alloc] initWithSeed:kRandomSeed];
  CGFloat diameter = self.texture.size.width;
  CGFloatPair bounds = [self radiusBoundsForCurrentShape];
  CGFloat bristleLength = (diameter / self.bristles) * self.thickness / self.maxThickness;
  CGSize bristleSize = CGSizeMakeUniform(bristleLength);
  CGFloat minRadius = bounds.first;
  CGFloat maxRadius = bounds.second;

  NSMutableArray *bristles = [NSMutableArray array];
  for (NSUInteger i = 0; i < self.bristles; ++i) {
    CGFloat angle = [self randomAngleForCurrentShape:random];
    CGFloat radius = [random randomDoubleBetweenMin:minRadius max:maxRadius];
    CGPoint center = CGPointMake(std::sin(angle), std::cos(angle)) * radius;
    [bristles addObject:[LTRotatedRect rectWithCenter:center + self.texture.size / 2
                                                 size:bristleSize angle:-angle]];
  }
  
  return bristles;
}

- (CGFloat)randomAngleForCurrentShape:(LTRandom *)random {
  static const double kFlatAngle = M_PI / 6.0;
  switch (self.shape) {
    case LTBristleBrushShapeRoundBlunt:
    case LTBristleBrushShapeRoundPoint:
    case LTBristleBrushShapeRoundFan:
      return [random randomDoubleBetweenMin:0 max:2 * M_PI];
    case LTBristleBrushShapeFlatBlunt:
    case LTBristleBrushShapeFlatPoint:
    case LTBristleBrushShapeFlatFan:
      CGFloat angle = [random randomDoubleBetweenMin:-kFlatAngle max:kFlatAngle];
      return angle + [random randomUnsignedIntegerBelow:2] * M_PI;
  }
}

- (CGFloatPair)radiusBoundsForCurrentShape {
  CGFloat diameter = self.texture.size.width;
  CGFloat bristleLength = (diameter / self.bristles) * self.thickness / self.maxThickness;
  CGFloat maxRadius;
  CGFloat minRadius;
  switch (self.shape) {
    case LTBristleBrushShapeRoundBlunt:
    case LTBristleBrushShapeFlatBlunt:
      maxRadius = MAX((diameter - bristleLength) / 2.0, 0.25 * diameter);
      minRadius = MIN(bristleLength, maxRadius / 2.0);
      break;
    case LTBristleBrushShapeRoundPoint:
    case LTBristleBrushShapeFlatPoint:
      maxRadius = (diameter - bristleLength) / 4.0;
      minRadius = bristleLength;
      break;
    case LTBristleBrushShapeRoundFan:
    case LTBristleBrushShapeFlatFan:
      maxRadius = MAX((diameter - bristleLength) / 2.0, 0.25 * diameter);
      minRadius = maxRadius / 4.0;
      break;
  }
  return CGFloatPair(minRadius, maxRadius);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (CGFloat)defaultSpacing {
  return 0.01;
}

LTPropertyWithoutSetter(CGFloat, thickness, Thickness, 0.1, 2, 0.2);
- (void)setThickness:(CGFloat)thickness {
  [self _verifyAndSetThickness:thickness];
  self.shouldUpdateBrush = YES;
}

LTPropertyWithoutSetter(NSUInteger, bristles, Bristles, 2, 30, 5);
- (void)setBristles:(NSUInteger)bristles {
  [self _verifyAndSetBristles:bristles];
  self.shouldUpdateBrush = YES;
}

- (void)setShape:(LTBristleBrushShape)shape {
  _shape = shape;
  self.shouldUpdateBrush = YES;
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"spacing", @"flow", @"opacity", @"angle", @"bristles", @"thickness"];
}

@end
