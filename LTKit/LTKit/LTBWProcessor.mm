// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTBWTonalityProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralFrameProcessor.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWProcessorFsh.h"
#import "LTShaderStorage+LTBWProcessorVsh.h"
#import "LTTexture+Factory.h"

@interface LTBWProcessor ()

/// If \c YES, the tone processor should run at the next processing round of this processor.
@property (nonatomic) BOOL toneProcessorInputChanged;

/// If \c YES, the vignette processor should run at the next processing round of this processor.
@property (nonatomic) BOOL vignetteProcessorInputChanged;

/// If \c YES, the outer frame processor should run at the next processing round of this processor.
@property (nonatomic) BOOL outerFrameProcessorInputChanged;

/// If \c YES, the inner frame processor should run at the next processing round of this processor.
@property (nonatomic) BOOL innerFrameProcessorInputChanged;

/// Processor for tone mapping the input image.
@property (strong, nonatomic) LTBWTonalityProcessor *toneProcessor;

/// Processor for generating the vignette texture.
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;

/// Processor for generating the outer frame texture.
@property (strong, nonatomic) LTProceduralFrameProcessor *outerFrameProcessor;

/// Processor for generating the inner frame texture.
@property (strong, nonatomic) LTProceduralFrameProcessor *innerFrameProcessor;

/// Identity curve used with colorGradientIntensity.
@property (nonatomic) cv::Mat4b identityCurve;

/// Mat copy of \c colorGradientTexture.
@property (nonatomic) cv::Mat4b colorGradientMat;

@end

@implementation LTBWProcessor

@synthesize grainTexture = _grainTexture;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  // Setup tonality.
  LTTexture *toneTexture = [LTTexture textureWithPropertiesOf:output];
  self.toneProcessor = [[LTBWTonalityProcessor alloc] initWithInput:input output:toneTexture];
  
  // Setup vignetting.
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  
  // Setup wide frame.
  LTTexture *outerFrameTexture = [self createFrameTextureWithInput:input];
  self.outerFrameProcessor = [[LTProceduralFrameProcessor alloc] initWithOutput:outerFrameTexture];
  
  // Setup narrow frame.
  LTTexture *innerFrameTexture = [self createFrameTextureWithInput:input];
  self.innerFrameProcessor = [[LTProceduralFrameProcessor alloc] initWithOutput:innerFrameTexture];
  
  NSDictionary *auxiliaryTextures =
      @{[LTBWProcessorFsh grainTexture]: self.grainTexture,
        [LTBWProcessorFsh vignettingTexture]: vignetteTexture,
        [LTBWProcessorFsh outerFrameTexture]: outerFrameTexture,
        [LTBWProcessorFsh innerFrameTexture]: innerFrameTexture};
  if (self = [super initWithVertexSource:[LTBWProcessorVsh source]
                          fragmentSource:[LTBWProcessorFsh source] sourceTexture:toneTexture
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
    [self setNeedsSubProcessing];
  }
  return self;
}

- (void)setDefaultValues {
  self.grainAmplitude = self.defaultGrainAmplitude;
  self.grainChannelMixer = self.defaultGrainChannelMixer;

  // Unlike the default LTProceduralVignetting spread, here the default is 0, so no vignetting is
  // initially seen.
  self.vignetteSpread = 0;

  self.identityCurve = [[LTColorGradient identityGradient] matWithSamplingPoints:256];
  self.colorGradientTexture = [LTTexture textureWithImage:self.identityCurve];
}

- (void)setupGrainTextureScalingWithOutputSize:(CGSize)size grain:(LTTexture *)grain {
  CGFloat xScale = size.width / grain.size.width;
  CGFloat yScale = size.height / grain.size.height;
  self[[LTBWProcessorVsh grainScaling]] = $(LTVector2(xScale, yScale));
}

- (CGSize)findConstrainedSizeWithSize:(CGSize)size maxDimension:(CGFloat)maxDimension {
  CGFloat largerDimension = MAX(size.width, size.height);
  // Size of the result shouldn't be larger than input size.
  CGFloat scaleFactor = MIN(1.0, maxDimension / largerDimension);
  return std::round(CGSizeMake(size.width * scaleFactor, size.height * scaleFactor));
}

- (LTTexture *)createVignettingTextureWithInput:(LTTexture *)input {
  static const CGFloat kVignettingMaxDimension = 256;
  CGSize vignettingSize = [self findConstrainedSizeWithSize:input.size
                                               maxDimension:kVignettingMaxDimension];
  LTTexture *vignetteTexture = [LTTexture byteRGBATextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (LTTexture *)createFrameTextureWithInput:(LTTexture *)input {
  static const CGFloat kFrameMaxDimension = 1024;
  CGSize frameSize = [self findConstrainedSizeWithSize:input.size maxDimension:kFrameMaxDimension];
  LTTexture *frameTexture = [LTTexture byteRGBATextureWithSize:frameSize];
  return frameTexture;
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  LTTexture *neutralNoise = [LTTexture textureWithImage:input];
  neutralNoise.wrap = LTTextureWrapRepeat;
  return neutralNoise;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)setNeedsSubProcessing {
  [self setNeedsToneProcessing];
  [self setNeedsVignetteProcessing];
  [self setNeedsOuterFrameProcessing];
  [self setNeedsInnerFrameProcessing];
}

- (void)setNeedsToneProcessing {
  self.toneProcessorInputChanged = YES;
}

- (void)setNeedsVignetteProcessing {
  self.vignetteProcessorInputChanged = YES;
}

- (void)setNeedsOuterFrameProcessing {
  self.outerFrameProcessorInputChanged = YES;
}

- (void)setNeedsInnerFrameProcessing {
  self.innerFrameProcessorInputChanged = YES;
}

- (void)runSubProcessors {
  if (self.toneProcessorInputChanged) {
    [self.toneProcessor process];
    self.toneProcessorInputChanged = NO;
  }
  if (self.vignetteProcessorInputChanged) {
    [self.vignetteProcessor process];
    self.vignetteProcessorInputChanged = NO;
  }
  if (self.outerFrameProcessorInputChanged) {
    [self.outerFrameProcessor process];
    self.outerFrameProcessorInputChanged = NO;
  }
  if (self.innerFrameProcessorInputChanged) {
    [self.innerFrameProcessor process];
    self.innerFrameProcessorInputChanged = NO;
  }
}

- (void)preprocess {
  [self runSubProcessors];
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyProxyWithoutSetter(LTVector3, colorFilter, ColorFilter, self.toneProcessor);
- (void)setColorFilter:(LTVector3)colorFilter {
  self.toneProcessor.colorFilter = colorFilter;
  [self setNeedsToneProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, brightness, Brightness, self.toneProcessor);
- (void)setBrightness:(CGFloat)brightness {
  self.toneProcessor.brightness = brightness;
  [self setNeedsToneProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, contrast, Contrast, self.toneProcessor);
- (void)setContrast:(CGFloat)contrast {
  self.toneProcessor.contrast = contrast;
  [self setNeedsToneProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, exposure, Exposure, self.toneProcessor);
- (void)setExposure:(CGFloat)exposure {
  self.toneProcessor.exposure = exposure;
  [self setNeedsToneProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, offset, Offset, self.toneProcessor);
- (void)setOffset:(CGFloat)offset {
  self.toneProcessor.offset = offset;
  [self setNeedsToneProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, structure, Structure, self.toneProcessor);
- (void)setStructure:(CGFloat)structure {
  self.toneProcessor.structure = structure;
  [self setNeedsToneProcessing];
}

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  if (!colorGradientTexture) {
    colorGradientTexture = [LTTexture textureWithImage:self.identityCurve];
  }
  _colorGradientTexture = colorGradientTexture;
  self.toneProcessor.colorGradientTexture = [colorGradientTexture clone];
  self.colorGradientMat = [self.colorGradientTexture image];
  [self processInternalColorGradientTexture];
  [self setNeedsToneProcessing];
}

LTPropertyWithoutSetter(CGFloat, colorGradientIntensity, ColorGradientIntensity, 0, 1, 1);
- (void)setColorGradientIntensity:(CGFloat)colorGradientIntensity {
  [self _verifyAndSetColorGradientIntensity:colorGradientIntensity];
  [self processInternalColorGradientTexture];
  [self setNeedsToneProcessing];
}

- (void)processInternalColorGradientTexture {
  [self.toneProcessor.colorGradientTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::addWeighted(self.identityCurve, 1 - self.colorGradientIntensity, self.colorGradientMat,
                    self.colorGradientIntensity, 0, *mapped);
  }];
}

#pragma mark -
#pragma mark Vignette
#pragma mark -

LTPropertyWithoutSetter(LTVector3, vignetteColor, VignetteColor,
                        LTVector3Zero, LTVector3One, LTVector3Zero);
- (void)setVignetteColor:(LTVector3)vignetteColor {
  [self _verifyAndSetVignetteColor:vignetteColor];
  self[@"vignetteColor"] = $(vignetteColor);
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
  self.vignetteProcessor.noiseAmplitude = vignetteNoiseAmplitude;
  [self setNeedsVignetteProcessing];
}

LTPropertyWithoutSetter(CGFloat, vignetteOpacity, VignetteOpacity, 0, 1, 0);
- (void)setVignetteOpacity:(CGFloat)vignetteOpacity {
  [self _verifyAndSetVignetteOpacity:vignetteOpacity];
  self[[LTBWProcessorFsh vignettingOpacity]] = @(vignetteOpacity);
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
  [self setAuxiliaryTexture:grainTexture withName:[LTBWProcessorFsh grainTexture]];
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
  self[[LTBWProcessorFsh grainChannelMixer]] = $(_grainChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 100, 1);
- (void)setGrainAmplitude:(CGFloat)grainAmplitude {
  [self _verifyAndSetGrainAmplitude:grainAmplitude];
  self[[LTBWProcessorFsh grainAmplitude]] = @(grainAmplitude);
}

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

LTPropertyProxyWithoutSetter(CGFloat, outerFrameWidth, OuterFrameWidth,
                             self.outerFrameProcessor, width, Width);
- (void)setOuterFrameWidth:(CGFloat)outerFrameWidth {
  self.outerFrameProcessor.width = outerFrameWidth;
  // Update the dependent inner frame.
  self.innerFrameProcessor.width = outerFrameWidth + self.innerFrameWidth;
  [self setNeedsInnerFrameProcessing];

  // Update outer frame.
  [self setNeedsOuterFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, outerFrameSpread, OuterFrameSpread,
                             self.outerFrameProcessor, spread, Spread);
- (void)setOuterFrameSpread:(CGFloat)outerFrameSpread {
  self.outerFrameProcessor.spread = outerFrameSpread;
  [self setNeedsOuterFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, outerFrameCorner, OuterFrameCorner,
                             self.outerFrameProcessor, corner, Corner);
- (void)setOuterFrameCorner:(CGFloat)outerFrameCorner {
  self.outerFrameProcessor.corner = outerFrameCorner;
  [self setNeedsOuterFrameProcessing];
}

- (void)setOuterFrameNoise:(LTTexture *)outerFrameNoise {
  self.outerFrameProcessor.noise = outerFrameNoise;
}

- (LTTexture *)outerFrameNoise {
  return self.outerFrameProcessor.noise;
}

LTPropertyProxyWithoutSetter(LTVector3, outerFrameNoiseChannelMixer, OuterFrameNoiseChannelMixer,
                             self.outerFrameProcessor, noiseChannelMixer, NoiseChannelMixer);
- (void)setOuterFrameNoiseChannelMixer:(LTVector3)outerFrameNoiseChannelMixer {
  self.outerFrameProcessor.noiseChannelMixer = outerFrameNoiseChannelMixer;
  [self setNeedsOuterFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, outerFrameNoiseAmplitude, OuterFrameNoiseAmplitude,
                             self.outerFrameProcessor, noiseAmplitude, NoiseAmplitude);
- (void)setOuterFrameNoiseAmplitude:(CGFloat)outerFrameNoiseAmplitude {
  self.outerFrameProcessor.noiseAmplitude = outerFrameNoiseAmplitude;
  [self setNeedsOuterFrameProcessing];
}

LTPropertyProxyWithoutSetter(LTVector3, outerFrameColor, OuterFrameColor,
                             self.outerFrameProcessor, color, Color);
- (void)setOuterFrameColor:(LTVector3)outerFrameColor {
  self.outerFrameProcessor.color = outerFrameColor;
  [self setNeedsOuterFrameProcessing];
}

#pragma mark -
#pragma mark Inner Frame
#pragma mark -

LTPropertyWithoutSetter(CGFloat, innerFrameWidth, InnerFrameWidth, 0, 25, 0);
- (void)setInnerFrameWidth:(CGFloat)innerFrameWidth {
  [self _verifyAndSetInnerFrameWidth:innerFrameWidth];
  LTParameterAssert(self.outerFrameWidth + innerFrameWidth <= self.innerFrameProcessor.maxWidth,
                    @"Sum of outer and inner width is above maximum value.");
  self.innerFrameProcessor.width = self.outerFrameWidth + innerFrameWidth;
  [self setNeedsInnerFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, innerFrameSpread, InnerFrameSpread,
                             self.innerFrameProcessor, spread, Spread);
- (void)setInnerFrameSpread:(CGFloat)innerFrameSpread {
  self.innerFrameProcessor.spread = innerFrameSpread;
  [self setNeedsInnerFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, innerFrameCorner, InnerFrameCorner,
                             self.innerFrameProcessor, corner, Corner);
- (void)setInnerFrameCorner:(CGFloat)innerFrameCorner {
  self.innerFrameProcessor.corner = innerFrameCorner;
  [self setNeedsInnerFrameProcessing];
}

- (void)setInnerFrameNoise:(LTTexture *)innerFrameNoise {
  self.innerFrameProcessor.noise = innerFrameNoise;
  [self setNeedsInnerFrameProcessing];
}

- (LTTexture *)innerFrameNoise {
  return self.innerFrameProcessor.noise;
}

LTPropertyProxyWithoutSetter(LTVector3, innerFrameNoiseChannelMixer, InnerFrameNoiseChannelMixer,
                             self.innerFrameProcessor, noiseChannelMixer, NoiseChannelMixer);
- (void)setInnerFrameNoiseChannelMixer:(LTVector3)innerFrameNoiseChannelMixer {
  self.innerFrameProcessor.noiseChannelMixer = innerFrameNoiseChannelMixer;
  [self setNeedsInnerFrameProcessing];
}

LTPropertyProxyWithoutSetter(CGFloat, innerFrameNoiseAmplitude, InnerFrameNoiseAmplitude,
                             self.innerFrameProcessor, noiseAmplitude, NoiseAmplitude);
- (void)setInnerFrameNoiseAmplitude:(CGFloat)innerFrameNoiseAmplitude {
  self.innerFrameProcessor.noiseAmplitude = innerFrameNoiseAmplitude;
  [self setNeedsInnerFrameProcessing];
}

LTPropertyProxyWithoutSetter(LTVector3, innerFrameColor, InnerFrameColor,
                             self.innerFrameProcessor, color, Color);
- (void)setInnerFrameColor:(LTVector3)innerFrameColor {
  self.innerFrameProcessor.color = innerFrameColor;
  [self setNeedsInnerFrameProcessing];
}

@end
