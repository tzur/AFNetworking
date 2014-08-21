// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTBilateralFilterProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTCurve.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAnalogFilmFsh.h"
#import "LTShaderStorage+LTAnalogFilmVsh.h"
#import "LTTexture+Factory.h"
#import "NSBundle+LTKitBundle.h"

@interface LTAnalogFilmProcessor ()

/// Returns YES is subprocessor used by this class is initialized, NO otherwise.
@property (nonatomic) BOOL subProcessorInitialized;

/// If \c YES, the vignette processor should run at the next processing round of this processor.
@property (nonatomic) BOOL vignetteProcessorInputChanged;

/// Internal vignetting processor.
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;

/// The generation id of the input texture that was used to create the current smooth texture.
@property (nonatomic) NSUInteger smoothTextureGenerationID;

/// Identity curve used with colorGradientIntensity.
@property (nonatomic) cv::Mat4b identityCurve;

@end

@implementation LTAnalogFilmProcessor

@synthesize grainTexture = _grainTexture;

// Downsampling wrt original image that is used when creating a smooth texture.
static const CGFloat kSmoothDownsampleFactor = 2.0;
static const NSUInteger kSmoothTextureIterations = 6;
static const CGFloat kSaturationScaling = 1.5;
static const ushort kLutSize = 256;
static const CGFloat kVignettingMaxDimension = 256;
static const LTVector3 kDefaultVignettingColor = LTVector3(0.0, 0.0, 0.0);
static const CGFloat kDefaultVignettingSpread = 0;
static const CGFloat kVignetteNoiseScaling = 100;
static const LTVector3 kDefaultGrainChannelMixer = LTVector3(1.0, 0.0, 0.0);

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup vignetting.
  LTTexture *vignetteTexture = [self createVignettingTextureWithSize:input.size];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  // Default color gradient.
  LTColorGradient *identityGradient = [LTColorGradient identityGradient];
  
  NSDictionary *auxiliaryTextures =
      @{[LTAnalogFilmFsh toneLUT]: [LTTexture textureWithImage:[LTCurve identity]],
        [LTAnalogFilmFsh colorGradient]: [identityGradient textureWithSamplingPoints:kLutSize],
        [LTAnalogFilmFsh grainTexture]: self.grainTexture,
        [LTAnalogFilmFsh vignettingTexture]: vignetteTexture};
  if (self = [super initWithVertexSource:[LTAnalogFilmVsh source]
                          fragmentSource:[LTAnalogFilmFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    [self setDefaultValues];
    _subProcessorInitialized = NO;
  }
  return self;
}

- (void)setDefaultValues {
  // Get default value of the color gradient texture, which was already set in the constructor.
  _colorGradientTexture = self.auxiliaryTextures[[LTAnalogFilmFsh colorGradient]];
  
  // Set values and update the shader using the setter code.
  self.grainChannelMixer = kDefaultGrainChannelMixer;
  self.structure = self.defaultStructure;
  self.saturation = self.defaultSaturation;
  self.vignetteOpacity = self.defaultVignetteOpacity;
  self.colorGradientAlpha = self.defaultColorGradientAlpha;
  self.blendMode = LTAnalogBlendModeNormal;
  
  // Initialize the default color gradient curve.
  self.identityCurve = [[LTColorGradient identityGradient] matWithSamplingPoints:256];
  
  // Update vignetting values of the subprocessor.
  self.vignetteColor = kDefaultVignettingColor;
  self.vignetteSpread = kDefaultVignettingSpread;
  
  // Since these properties are encapsulated by LUT and default LUT is set in the constructor, no
  // need update the shader after setting the following properties.
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
  self[[LTAnalogFilmVsh grainScaling]] = $(LTVector2(xScale, yScale));
}

- (CGSize)aspectFitSize:(CGSize)size toSize:(CGFloat)maxDimension {
  CGFloat largerDimension = MAX(size.width, size.height);
  // Size of the result shouldn't be larger than input size.
  CGFloat scaleFactor = MIN(1.0, maxDimension / largerDimension);
  return std::floor(CGSizeMake(size.width * scaleFactor, size.height * scaleFactor));
}

- (LTTexture *)createVignettingTextureWithSize:(CGSize)size {
  CGSize vignettingSize = [self aspectFitSize:size toSize:kVignettingMaxDimension];
  LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  LTTexture *neutralNoise = [LTTexture textureWithImage:input];
  neutralNoise.wrap = LTTextureWrapRepeat;
  return neutralNoise;
}

- (void)updateSmoothTextureIfNecessary {
  if (self.smoothTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTAnalogFilmFsh smoothTexture]]) {
    self.smoothTextureGenerationID = self.inputTexture.generationID;
    [self setAuxiliaryTexture:[self createSmoothTexture:self.inputTexture]
                     withName:[LTAnalogFilmFsh smoothTexture]];
  }
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)setNeedsSubProcessing {
  [self setNeedsVignetteProcessing];
}

- (void)setNeedsVignetteProcessing {
  self.vignetteProcessorInputChanged = YES;
}

- (void)runSubProcessors {
  if (self.vignetteProcessorInputChanged) {
    [self.vignetteProcessor process];
    self.vignetteProcessorInputChanged = NO;
  }
}

- (void)preprocess {
  [self runSubProcessors];
  [self updateSmoothTextureIfNecessary];
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyWithoutSetter(CGFloat, brightness, Brightness, -1, 1, 0);
- (void)setBrightness:(CGFloat)brightness {
  [self _verifyAndSetBrightness:brightness];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, offset, Offset, -1, 1, 0);
- (void)setOffset:(CGFloat)offset {
  [self _verifyAndSetOffset:offset];
  [self updateToneLUT];
}

LTPropertyWithoutSetter(CGFloat, structure, Structure, -1, 1, 0);
- (void)setStructure:(CGFloat)structure {
  [self _verifyAndSetStructure:structure];
  // Remap [-1, 1] -> [0.25, 4].
  CGFloat remap = std::powf(4.0, structure);
  self[[LTAnalogFilmFsh structure]] = @(remap);
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 3].
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[[LTAnalogFilmFsh saturation]] = @(remap);
}

#pragma mark -
#pragma mark Vignetting
#pragma mark -

LTPropertyWithoutSetter(LTVector3, vignetteColor, VignetteColor,
                        LTVector3Zero, LTVector3One, LTVector3Zero);
- (void)setVignetteColor:(LTVector3)vignetteColor {
  [self _verifyAndSetVignetteColor:vignetteColor];
  self[[LTAnalogFilmFsh vignetteColor]] = $(vignetteColor);
}

LTPropertyProxyWithoutSetter(CGFloat, vignetteSpread, VignetteSpread,
                             self.vignetteProcessor, spread, Spread);
- (void)setVignetteSpread:(CGFloat)vignetteSpread {
  self.vignetteProcessor.spread = vignetteSpread;
  [self setNeedsVignetteProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, vignetteCorner, VignetteCorner,
                             self.vignetteProcessor, corner, Corner);
- (void)setVignetteCorner:(CGFloat)vignetteCorner {
  self.vignetteProcessor.corner = vignetteCorner;
  [self setNeedsVignetteProcessing];
}

- (void)setVignetteNoise:(LTTexture *)vignetteNoise {
  self.vignetteProcessor.noise = vignetteNoise;
  [self setNeedsVignetteProcessing];
}

- (LTTexture *)vignetteNoise {
  return self.vignetteProcessor.noise;
}

LTPropertyProxyWithoutSetter(LTVector3, vignetteNoiseChannelMixer, VignetteNoiseChannelMixer,
                             self.vignetteProcessor, noiseChannelMixer, NoiseChannelMixer);
- (void)setVignetteNoiseChannelMixer:(LTVector3)vignetteNoiseChannelMixer {
  self.vignetteProcessor.noiseChannelMixer = vignetteNoiseChannelMixer;
  [self setNeedsVignetteProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, vignetteNoiseAmplitude, VignetteNoiseAmplitude,
                             self.vignetteProcessor, noiseAmplitude, NoiseAmplitude);
- (void)setVignetteNoiseAmplitude:(CGFloat)vignetteNoiseAmplitude {
  self.vignetteProcessor.noiseAmplitude = vignetteNoiseAmplitude * kVignetteNoiseScaling;
  [self setNeedsVignetteProcessing];
}

LTPropertyWithoutSetter(CGFloat, vignetteOpacity, VignetteOpacity, 0, 1, 0);
- (void)setVignetteOpacity:(CGFloat)vignetteOpacity {
  [self _verifyAndSetVignetteOpacity:vignetteOpacity];
  self[[LTAnalogFilmFsh vignettingOpacity]] = @(vignetteOpacity);
}

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
  [self setAuxiliaryTexture:grainTexture withName:[LTAnalogFilmFsh grainTexture]];
  [self setupGrainTextureScalingWithOutputSize:self.outputSize grain:self.grainTexture];
}

- (BOOL)isValidGrainTexture:(LTTexture *)texture {
  BOOL isTilable = LTIsPowerOfTwo(texture.size) && (texture.wrap == LTTextureWrapRepeat);
  BOOL matchesOutputSize = (texture.size == self.outputSize);
  return isTilable || matchesOutputSize;
}

LTPropertyWithoutSetter(LTVector3, grainChannelMixer, GrainChannelMixer,
                        LTVector3Zero, LTVector3One, LTVector3(1, 0, 0));
- (void)setGrainChannelMixer:(LTVector3)grainChannelMixer {
  [self _verifyAndSetGrainChannelMixer:grainChannelMixer];
  _grainChannelMixer = grainChannelMixer / std::sum(grainChannelMixer);
  self[[LTAnalogFilmFsh grainChannelMixer]] = $(_grainChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 1, 0);
- (void)setGrainAmplitude:(CGFloat)grainAmplitude {
  [self _verifyAndSetGrainAmplitude:grainAmplitude];
  self[[LTAnalogFilmFsh grainAmplitude]] = @(grainAmplitude);
}

#pragma mark -
#pragma mark Gradient Texture
#pragma mark -

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  if (!colorGradientTexture) {
    colorGradientTexture = [LTTexture textureWithImage:self.identityCurve];
  } else {
    LTParameterAssert(colorGradientTexture.size.height == 1,
                      @"colorGradientTexture height is not one");
    LTParameterAssert(colorGradientTexture.size.width <= kLutSize,
                      @"colorGradientTexture width is larger than kLutSize");
  }
  
  _colorGradientTexture = colorGradientTexture;
  [self setAuxiliaryTexture:colorGradientTexture withName:[LTAnalogFilmFsh colorGradient]];
}

- (void)setBlendMode:(LTAnalogBlendMode)blendMode {
  _blendMode = blendMode;
  self[[LTAnalogFilmFsh blendMode]] = @(blendMode);
}

LTPropertyWithoutSetter(CGFloat, colorGradientAlpha, ColorGradientAlpha, 0, 1, 0);
- (void)setColorGradientAlpha:(CGFloat)colorGradientAlpha {
  [self _verifyAndSetColorGradientAlpha:colorGradientAlpha];
  self[[LTAnalogFilmFsh colorGradientAlpha]] = @(colorGradientAlpha);
}

#pragma mark -
#pragma mark Tone LUT
#pragma mark -

- (void)updateToneLUT {
  cv::Mat1b toneCurve(1, kLutSize);
  
  cv::Mat1b brightnessCurve(1, kLutSize);
  if (self.brightness >= self.defaultBrightness) {
    brightnessCurve = [LTCurve positiveBrightness];
  } else {
    brightnessCurve = [LTCurve negativeBrightness];
  }
  
  cv::Mat1b contrastCurve(1, kLutSize);
  if (self.contrast >= self.defaultContrast) {
    contrastCurve = [LTCurve positiveContrast];
  } else {
    contrastCurve = [LTCurve negativeContrast];
  }
  
  float brightness = std::abs(self.brightness);
  float contrast = std::abs(self.contrast);
  cv::LUT((1.0 - contrast) * [LTCurve identity] + contrast * contrastCurve,
          (1.0 - brightness) * [LTCurve identity]  + brightness * brightnessCurve,
          toneCurve);
  
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  [(LTTexture *)self.auxiliaryTextures[[LTAnalogFilmFsh toneLUT]] load:toneCurve];
}

@end
