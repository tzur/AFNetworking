// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTRoundBrush.h"

#import "LTGLKitExtensions.h"
#import "LTProgram.h"
#import "LTRectDrawer.h"
#import "LTShaderStorage+LTBrushShaderVsh.h"
#import "LTShaderStorage+LTRoundBrushShaderFsh.h"
#import "LTTexture+Factory.h"

#import "LTGLTexture.h"

#import "LTFbo.h"

@interface LTBrush ()
@property (strong, nonatomic) LTTexture *texture;
@property (strong, nonatomic) LTProgram *program;
@property (strong, nonatomic) LTRectDrawer *drawer;
@end

@interface LTRoundBrush ()

/// Indicates that the brush should be updated before drawing.
@property (nonatomic) BOOL shouldUpdateBrush;

@end

@implementation LTRoundBrush

/// Size (in pixels) of the brush texture on the base level.
static const uint kBaseLevelDiameter = 256;

/// Sigma used for generating the gaussian, yielding a falloff which is very close to 0 at the
/// texture edges.
static const CGFloat kBrushGaussianSigma = 0.3;

- (instancetype)init {
  if (self = [super init]) {
    [self setCircularBrushDefaults];
    [self updateBrushForCurrentProperties];
  }
  return self;
}

- (void)setCircularBrushDefaults {
  self.hardness = kDefaultHardness;
  self.intensity = kDefaultIntensity;
}

- (LTProgram *)createProgram {
  return [[LTProgram alloc] initWithVertexSource:[LTBrushShaderVsh source]
                                  fragmentSource:[LTRoundBrushShaderFsh source]];
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
  LTAssert(!((kBaseLevelDiameter & (kBaseLevelDiameter - 1))),
             @"base level diameter must be power of two");
  
  self.shouldUpdateBrush = NO;
  Matrices levels;
  for (uint diameter = kBaseLevelDiameter; diameter > 16; diameter /= 2) {
    levels.push_back([self createBrushMatForDiameter:diameter]);
  }
  
  self.texture = [LTGLTexture textureWithMipmapImages:levels];
  self.texture.minFilterInterpolation = LTTextureInterpolationLinearMipmapLinear;
  self.texture.magFilterInterpolation = LTTextureInterpolationLinear;
  LogDebug(@"generated new brush texture");
}

- (cv::Mat)createBrushMatForDiameter:(uint)diameter {
  using half_float::half;
  cv::Mat1hf mat(diameter, diameter);
  mat = half(0.0);
  int radius = mat.rows / 2 - 1;
  CGFloat sigma = kBrushGaussianSigma;
  CGFloat inv2SigmaSquare = 1.0 / (2.0 * sigma * sigma);
  for (int i = 0; i < 2 * radius; ++i) {
    for (int j = 0; j < 2 * radius; ++j) {
      CGFloat y = (i - radius + 0.5) / radius;
      CGFloat x = (j - radius + 0.5) / radius;
      CGFloat squaredDistance = x * x + y * y;
      CGFloat arg = -squaredDistance * inv2SigmaSquare;
      CGFloat value = std::exp((1 - self.hardness) * arg);
      CGFloat edgeFactor = 1 - MIN(1, MAX(0, (std::sqrt(squaredDistance) * radius - radius + 0.5)));
      mat(i+1, j+1) = half(edgeFactor * value);
    }
  }
  return mat;
}

- (void)updateProgramForCurrentProperties {
  self.program[[LTRoundBrushShaderFsh opacity]] = @(self.opacity);
  self.program[[LTRoundBrushShaderFsh flow]] = @(self.flow);
  self.program[[LTRoundBrushShaderFsh intensity]] = $(self.intensity);
}

#pragma mark -
#pragma mark Properties
#pragma mark -

LTBoundedPrimitivePropertyImplementWithoutSetter(GLKVector4, intensity, Intensity,
                                                 GLKVector4Make(0, 0, 0, 0),
                                                 GLKVector4Make(1, 1, 1, 1),
                                                 GLKVector4Make(1, 1, 1, 1));

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, hardness, Hardness, 0, 1, 1, ^{
  self.shouldUpdateBrush = YES;
});


- (void)setIntensity:(GLKVector4)intensity {
  LTParameterAssert(intensity.x >= self.minIntensity.x);
  LTParameterAssert(intensity.y >= self.minIntensity.y);
  LTParameterAssert(intensity.z >= self.minIntensity.z);
  LTParameterAssert(intensity.w >= self.minIntensity.w);
  LTParameterAssert(intensity.x <= self.maxIntensity.x);
  LTParameterAssert(intensity.y <= self.maxIntensity.y);
  LTParameterAssert(intensity.z <= self.maxIntensity.z);
  LTParameterAssert(intensity.w <= self.maxIntensity.w);
  _intensity = intensity;
  [self updateProgramForCurrentProperties];
}

- (NSArray *)adjustableProperties {
  return @[@"scale", @"spacing", @"opacity", @"flow", @"hardness"];
}

@end
