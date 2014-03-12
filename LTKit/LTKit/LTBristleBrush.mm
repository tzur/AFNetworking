// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBristleBrush.h"

#import "LTCGExtensions.h"
#import "LTFbo.h"
#import "LTGLContext.h"
#import "LTMathUtils.h"
#import "LTRectDrawer+PassthroughShader.h"
#import "LTRotatedRect.h"
#import "LTTexture+Factory.h"

@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@end

@interface LTBristleBrush ()

/// Indicates that the brush should be updated before drawing.
@property (nonatomic) BOOL shouldUpdateBrush;

/// Fbo used for updating the brush texture.
@property (strong, nonatomic) LTFbo *brushFbo;

/// Drawer used to draw the bristles when updating the brush texture.
@property (strong, nonatomic) LTRectDrawer *bristleDrawer;

@end

@implementation LTBristleBrush

/// Override the default spacing of the \c LTBrush.
static const CGFloat kDefaultSpacing = 0.01;

/// Size (in pixels) of the brush texture on the base level.
static const uint kBaseLevelDiameter = 256;

/// Diameter for the bristle texture.
static const uint kBristleDiameter = 64;

/// Sigma of the gaussian representing each bristle.
static const CGFloat kBristleSigma = 0.4;

- (instancetype)init {
  if (self = [super init]) {
    [self setBristleBrushDefaults];
    self.brushFbo = [self createBrushFbo];
    self.bristleDrawer = [self createBristleDrawer];
  }
  return self;
}

- (void)setBristleBrushDefaults {
  self.shape = LTBristleBrushShapeRound;
  self.spacing = kDefaultSpacing;
  self.bristles = kDefaultBristles;
  self.thickness = kDefaultThickness;
}

- (LTTexture *)createTexture {
  return [LTTexture textureWithSize:CGSizeMakeUniform(kBaseLevelDiameter)
                          precision:LTTexturePrecisionHalfFloat format:LTTextureFormatRed
                     allocateMemory:YES];
}

- (LTFbo *)createBrushFbo {
  return [[LTFbo alloc] initWithTexture:self.texture];
}

- (LTRectDrawer *)createBristleDrawer {
  cv::Mat bristleMat = [self createGaussianWithDiameter:kBristleDiameter sigma:kBristleSigma];
  return [[LTRectDrawer alloc] initWithSourceTexture:[LTTexture textureWithImage:bristleMat]];
}

- (cv::Mat)createGaussianWithDiameter:(uint)diameter sigma:(CGFloat)sigma {
  using half_float::half;
  cv::Mat4hf mat(diameter, diameter);
  mat = half(0.0);
  int radius = mat.rows / 2 - 1;
  CGFloat inv2SigmaSquare = 1.0 / (2.0 * sigma * sigma);
  for (int i = 0; i < 2 * radius; ++i) {
    for (int j = 0; j < 2 * radius; ++j) {
      CGFloat y = (i - radius + 0.5) / radius;
      CGFloat x = (j - radius + 0.5) / radius;
      CGFloat squaredDistance = x * x + y * y;
      CGFloat arg = -squaredDistance * inv2SigmaSquare;
      CGFloat value = (squaredDistance <= 1.0) ? std::exp(arg) : 0;
      mat(i+1, j+1) = half(value);
    }
  }
  
  return mat;
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
  
  [self.brushFbo clearWithColor:GLKVector4Make(0, 0, 0, 1)];
  LTGLContext *context = [LTGLContext currentContext];
  [context executeAndPreserveState:^{
    context.blendEnabled = YES;
    context.blendFunc = kLTGLContextBlendFuncNormal;
    [self.bristleDrawer drawRotatedRects:bristles inFramebuffer:self.brushFbo
                        fromRotatedRects:sources];
  }];
}

// TODO:(amit) implement a better mechanism that avoids collisions and takes the shape into account.
- (NSArray *)bristlesForCurrentProperties {
  // We're using a contant seed since we prefer something pseudo-random, that will generate the same
  // brush under the same parameters. This is important so users can duplicate a previous result.
  static const uint kRandomSeed = 10;
  srand48(kRandomSeed);
  CGFloat diameter = self.texture.size.width;
  CGFloat bristleLength = (diameter / self.bristles) * self.thickness / kMaxThickness;
  CGFloat maxRadius = MAX((diameter - bristleLength) / 2.0, 0.25 * diameter);
  CGFloat minRadius = MIN(bristleLength, maxRadius / 2.0);
  CGSize bristleSize = CGSizeMakeUniform(bristleLength);
  
  NSMutableArray *bristles = [NSMutableArray array];
  for (NSUInteger i = 0; i < self.bristles; ++i) {
    CGFloat angle = drand48() * 2 * M_PI;
    CGFloat radius = drand48() * (maxRadius - minRadius) + minRadius;
    CGPoint center = CGPointMake(std::sin(angle), std::cos(angle)) * radius;
    [bristles addObject:[LTRotatedRect rectWithCenter:center + self.brushFbo.size / 2
                                                 size:bristleSize angle:-angle]];
  }
  
  return bristles;
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, thickness, Thickness, 0, 2, 0.1, ^{
  self.shouldUpdateBrush = YES;
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(NSUInteger, bristles, Bristles, 2, 100, 10, ^{
  self.shouldUpdateBrush = YES;
});

@end
