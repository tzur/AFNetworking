// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAnalogFilmFsh.h"
#import "LTShaderStorage+LTAnalogFilmVsh.h"
#import "LTTexture+Factory.h"
#import "NSBundle+LTKitBundle.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTAnalogFilmProcessor ()

@property (nonatomic) BOOL subProcessorsInitialized;
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;
@property (nonatomic) CGSize outputSize;

@end

@implementation LTAnalogFilmProcessor

@synthesize grainTexture = _grainTexture;

// The follow matrices hold the curves data.
static cv::Mat1b kIdentityCurve;
static cv::Mat1b kPositiveBrightnessCurve;
static cv::Mat1b kNegativeBrightnessCurve;
static cv::Mat1b kPositiveContrastCurve;
static cv::Mat1b kNegativeContrastCurve;

static const CGFloat kSmoothDownsampleFactor = 2.0;
static const NSUInteger kSmoothTextureIterations = 6;
static const CGFloat kSaturationScaling = 1.5;
static const CGFloat kGrainAmplitudeScaling = 0.5;
static const CGFloat kColorGradientAlphaScaling = 0.5;
static const CGFloat kVignettingMaxDimension = 256;
static const GLKVector3 kDefaultVignettingColor = GLKVector3Make(0.0, 0.0, 0.0);
static const CGFloat kDefaultVignettingSpread = 0;
static const GLKVector3 kDefaultGrainChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTAnalogFilmVsh source]
                                                fragmentSource:[LTAnalogFilmFsh source]];
  // Setup vignetting.
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];
  
  NSDictionary *auxiliaryTextures =
  @{[LTAnalogFilmFsh smoothTexture]: [self createSmoothTexture:input],
    [LTAnalogFilmFsh toneLUT]: [LTTexture textureWithImage:kIdentityCurve],
    [LTAnalogFilmFsh colorGradient]: [identityGradient textureWithSamplingPoints:256],
    [LTAnalogFilmFsh grainTexture]: self.grainTexture,
    [LTAnalogFilmFsh vignettingTexture]: vignetteTexture};
  if (self = [super initWithProgram:program sourceTexture:input auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
    _outputSize = output.size;
    _subProcessorsInitialized = NO;
  }
  return self;
}

+ (void)initialize {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    kIdentityCurve = LTLoadMatFromBundle([NSBundle LTKitBundle], @"IdentityCurve.png");
    kPositiveBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"PositiveBrightnessCurve.png");
    kNegativeBrightnessCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                   @"NegativeBrightnessCurve.png");
    kPositiveContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"PositiveContrastCurve.png");
    kNegativeContrastCurve = LTLoadMatFromBundle([NSBundle LTKitBundle],
                                                 @"NegativeContrastCurve.png");
  });
}

- (void)setDefaultValues {
  // Set values and push them to the shader.
  _grainChannelMixer = kDefaultGrainChannelMixer;
  self[@"grainChannelMixer"] = $(self.grainChannelMixer);
  _vignetteColor = kDefaultVignettingColor;
  self[@"vignetteColor"] = $(self.vignetteColor);
  self.vignettingSpread = kDefaultVignettingSpread;
  _colorGradientTexture = self.auxiliaryTextures[[LTAnalogFilmFsh colorGradient]];
  // Set values and update the shader using the setter code.
  self.structure = self.defaultStructure;
  self.saturation = self.defaultSaturation;
  self.vignettingOpacity = self.defaultVignettingOpacity;
  // No need to update the shader of the following properties.
  _brightness = self.defaultBrightness;
  _contrast = self.defaultContrast;
  _exposure = self.defaultExposure;
  _offset = self.defaultOffset;
}

- (LTTexture *)createSmoothTexture:(LTTexture *)input {
  CGFloat width = MAX(1.0, std::round(input.size.width / kSmoothDownsampleFactor));
  CGFloat height = MAX(1.0, std::round(input.size.height / kSmoothDownsampleFactor));
  
  LTTexture *smooth = [LTTexture byteRGBATextureWithSize:CGSizeMake(width, height)];
  
  LTBilateralFilterProcessor *smoother =
    [[LTBilateralFilterProcessor alloc] initWithInput:input outputs:@[smooth]];
  
  smoother.iterationsPerOutput = @[@(kSmoothTextureIterations)];
  smoother.rangeSigma = 0.1;
  [smoother process];
  
  return smooth;
}

- (void)setupGrainTextureScalingWithOutputSize:(CGSize)size grain:(LTTexture *)grain {
  CGFloat xScale = size.width / grain.size.width;
  CGFloat yScale = size.height / grain.size.height;
  self[@"grainScaling"] = $(GLKVector2Make(xScale, yScale));
}

- (CGSize)findConstrainedSizeWithSize:(CGSize)size maxDimension:(CGFloat)maxDimension {
  CGFloat largerDimension = MAX(size.width, size.height);
  // Size of the result shouldn't be larger than input size.
  CGFloat scaleFactor = MIN(1.0, maxDimension / largerDimension);
  return std::round(CGSizeMake(size.width * scaleFactor, size.height * scaleFactor));
}

- (LTTexture *)createVignettingTextureWithInput:(LTTexture *)input {
  CGSize vignettingSize = [self findConstrainedSizeWithSize:input.size
                                               maxDimension:kVignettingMaxDimension];
  LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  LTTexture *neutralNoise = [LTTexture textureWithImage:input];
  neutralNoise.wrap = LTTextureWrapRepeat;
  return neutralNoise;
}

- (void)initializeSubProcessors {
  [self.vignetteProcessor process];
  self.subProcessorsInitialized = YES;
}

- (id<LTImageProcessorOutput>)process {
  if (!self.subProcessorsInitialized) {
    [self initializeSubProcessors];
  }
  return [super process];
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, brightness, Brightness, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, contrast, Contrast, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, exposure, Exposure, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, offset, Offset, -1, 1, 0, ^{
  [self updateToneLUT];
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, structure, Structure, -1, 1, 0, ^{
  _structure = structure;
  // Remap [-1, 1] -> [0.25, 4].
  CGFloat remap = std::powf(4.0, structure);
  self[@"structure"] = @(remap);
});

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, saturation, Saturation, -1, 1, 0, ^{
  _saturation = saturation;
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[@"saturation"] = @(remap);
});

#pragma mark -
#pragma mark Vignetting
#pragma mark -

- (void)setVignetteColor:(GLKVector3)vignetteColor {
  LTParameterAssert(GLKVectorInRange(vignetteColor, 0.0, 1.0), @"Color filter is out of range.");
  _vignetteColor = vignetteColor;
  self[@"vignetteColor"] = $(vignetteColor);
  [self.vignetteProcessor process];
}

- (void)setVignettingSpread:(CGFloat)vignettingSpread {
  self.vignetteProcessor.spread = vignettingSpread;
  [self.vignetteProcessor process];
}

- (CGFloat)vignettingSpread {
  return self.vignetteProcessor.spread;
}

- (void)setVignettingCorner:(CGFloat)vignettingCorner {
  self.vignetteProcessor.corner = vignettingCorner;
  [self.vignetteProcessor process];
}

- (CGFloat)vignettingCorner {
  return self.vignetteProcessor.corner;
}

- (void)setVignettingNoise:(LTTexture *)vignettingNoise {
  self.vignetteProcessor.noise = vignettingNoise;
  [self.vignetteProcessor process];
}

- (LTTexture *)vignettingNoise {
  return self.vignetteProcessor.noise;
}

- (void)setVignettingNoiseChannelMixer:(GLKVector3)vignettingNoiseChannelMixer {
  self.vignetteProcessor.noiseChannelMixer = vignettingNoiseChannelMixer;
  [self.vignetteProcessor process];
}

- (GLKVector3)vignettingNoiseChannelMixer {
  return self.vignetteProcessor.noiseChannelMixer;
}

- (void)setVignettingNoiseAmplitude:(CGFloat)vignettingNoiseAmplitude {
  self.vignetteProcessor.noiseAmplitude = vignettingNoiseAmplitude;
  [self.vignetteProcessor process];
}

- (CGFloat)vignettingNoiseAmplitude {
  return self.vignetteProcessor.noiseAmplitude;
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, vignettingOpacity, VignettingOpacity,
  0, 1, 0, ^{
  _vignettingOpacity = vignettingOpacity;
  self[@"vignettingOpacity"] = @(vignettingOpacity);
});

#pragma mark -
#pragma mark Grain
#pragma mark -

- (LTTexture *)grainTexture {
  if (!_grainTexture) {
    _grainTexture = [self createNeutralNoise];
  }
  return _grainTexture;
}

- (void)setGrainTexture:(LTTexture *)grainTexture {
  LTParameterAssert([self isValidGrainTexture:grainTexture],
                    @"Grain texture should be either tileable or match the output size.");
  _grainTexture = grainTexture;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAnalogFilmFsh grainTexture]] = grainTexture;
  self.auxiliaryTextures = auxiliaryTextures;
  [self setupGrainTextureScalingWithOutputSize:self.outputSize grain:self.grainTexture];
  [self process];
}

- (BOOL)isValidGrainTexture:(LTTexture *)texture {
  BOOL isTilable = LTIsPowerOfTwo(texture.size) && (texture.wrap == LTTextureWrapRepeat);
  BOOL matchesOutputSize = (texture.size == self.outputSize);
  return isTilable || matchesOutputSize;
}

-(void)setGrainChannelMixer:(GLKVector3)grainChannelMixer {
  _grainChannelMixer = grainChannelMixer / std::sum(grainChannelMixer);
  self[@"grainChannelMixer"] = $(_grainChannelMixer);
  [self process];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 1,
  0, ^{
  _grainAmplitude = grainAmplitude;
  self[@"grainAmplitude"] = @(grainAmplitude * kGrainAmplitudeScaling);
  [self process];
});

#pragma mark -
#pragma mark Gradient Texture
#pragma mark -

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  LTParameterAssert(colorGradientTexture.size.height == 1,
                    @"colorGradientTexture height is not one");
  LTParameterAssert(colorGradientTexture.size.width <= 256,
                    @"colorGradientTexture width is larger than 256");
  
  _colorGradientTexture = colorGradientTexture;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTAnalogFilmFsh colorGradient]] = colorGradientTexture;
  self.auxiliaryTextures = auxiliaryTextures;
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, colorGradientAlpha, ColorGradientAlpha,
  -1, 1, 0, ^{
  _colorGradientAlpha = colorGradientAlpha;
  self[@"colorGradientAlpha"] = @(colorGradientAlpha * kColorGradientAlphaScaling);
});

#pragma mark -
#pragma mark Tone LUT
#pragma mark -

- (void)updateToneLUT {
  static const ushort kLutSize = 256;
  
  cv::Mat1b toneCurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= kDefaultBrightness) {
    brightnessCurve = kPositiveBrightnessCurve;
  } else {
    brightnessCurve = kNegativeBrightnessCurve;
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= kDefaultContrast) {
    contrastCurve = kPositiveContrastCurve;
  } else {
    contrastCurve = kNegativeContrastCurve;
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * kIdentityCurve + contrast * contrastCurve,
          (1.0 - brightness) * kIdentityCurve + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  [auxiliaryTextures[[LTAnalogFilmFsh toneLUT]] load:toneCurve];
  self.auxiliaryTextures = auxiliaryTextures;
}

@end
