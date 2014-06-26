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
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTBWProcessorVsh source]
                                                fragmentSource:[LTBWProcessorFsh source]];
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
  if (self = [super initWithProgram:program sourceTexture:toneTexture
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
  self[[LTBWProcessorVsh grainScaling]] = $(GLKVector2Make(xScale, yScale));
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

- (void)process {
  [self runSubProcessors];
  return [super process];
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTProxyPropertyWithSetter(GLKVector3, colorFilter, ColorFilter, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

LTProxyPropertyWithSetter(CGFloat, brightness, Brightness, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

LTProxyPropertyWithSetter(CGFloat, contrast, Contrast, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

LTProxyPropertyWithSetter(CGFloat, exposure, Exposure, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

LTProxyPropertyWithSetter(CGFloat, offset, Offset, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

LTProxyPropertyWithSetter(CGFloat, structure, Structure, self.toneProcessor, ^{
  [self setNeedsToneProcessing];
});

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  if (!colorGradientTexture) {
    colorGradientTexture = [LTTexture textureWithImage:self.identityCurve];
  }
  _colorGradientTexture = colorGradientTexture;
  self.toneProcessor.colorGradientTexture = [colorGradientTexture clone];
  self.colorGradientMat = cv::Mat();
  [self setNeedsToneProcessing];
}

LTPropertyWithSetter(CGFloat, colorGradientIntensity, ColorGradientIntensity, 0, 1, 1, ^{
  [self processInternalColorGradientTexture];
  [self setNeedsToneProcessing];
});

- (void)processInternalColorGradientTexture {
  if (self.colorGradientMat.empty()) {
    self.colorGradientMat = [self.colorGradientTexture image];
  }

  [self.toneProcessor.colorGradientTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::addWeighted(self.identityCurve, 1 - self.colorGradientIntensity, self.colorGradientMat,
                    self.colorGradientIntensity, 0, *mapped);
  }];
}

#pragma mark -
#pragma mark Vignette
#pragma mark -

LTPropertyWithSetter(GLKVector3, vignetteColor, VignetteColor,
                     GLKVector3Zero, GLKVector3One, GLKVector3Zero, ^{
  self[@"vignetteColor"] = $(vignetteColor);
});

LTProxyCustomProperty(CGFloat, vignetteSpread, VignetteSpread,
                      self.vignetteProcessor, spread, Spread, ^{
  [self setNeedsVignetteProcessing];
});

LTProxyCustomProperty(CGFloat, vignetteCorner, VignetteCorner,
                      self.vignetteProcessor, corner, Corner, ^{
  [self setNeedsVignetteProcessing];
});

- (void)setVignetteNoise:(LTTexture *)vignetteNoise {
  self.vignetteProcessor.noise = vignetteNoise;
  [self setNeedsVignetteProcessing];
}

- (LTTexture *)vignetteNoise {
  return self.vignetteProcessor.noise;
}

LTProxyCustomProperty(GLKVector3, vignetteNoiseChannelMixer, VignetteNoiseChannelMixer,
                      self.vignetteProcessor, noiseChannelMixer, NoiseChannelMixer, ^{
  [self setNeedsVignetteProcessing];
});

LTProxyCustomProperty(CGFloat, vignetteNoiseAmplitude, VignetteNoiseAmplitude,
                      self.vignetteProcessor, noiseAmplitude, NoiseAmplitude, ^{
  [self setNeedsVignetteProcessing];
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
  [self setAuxiliaryTexture:grainTexture withName:[LTBWProcessorFsh grainTexture]];
  [self setupGrainTextureScalingWithOutputSize:self.outputSize grain:self.grainTexture];
}

- (BOOL)isValidGrainTexture:(LTTexture *)texture {
  BOOL isTilable = LTIsPowerOfTwo(texture.size) && (texture.wrap == LTTextureWrapRepeat);
  BOOL matchesOutputSize = (texture.size == self.outputSize);
  return isTilable || matchesOutputSize;
}

LTPropertyWithSetter(GLKVector3, grainChannelMixer, GrainChannelMixer,
                     GLKVector3Zero, GLKVector3One, GLKVector3Make(1, 0, 0), ^{
  _grainChannelMixer = grainChannelMixer / std::sum(grainChannelMixer);
  self[[LTBWProcessorFsh grainChannelMixer]] = $(_grainChannelMixer);
});

LTPropertyWithSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 100, 1, ^{
  self[[LTBWProcessorFsh grainAmplitude]] = @(grainAmplitude);
});

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

LTProxyCustomProperty(CGFloat, outerFrameWidth, OuterFrameWidth,
                      self.outerFrameProcessor, width, Width, ^{
  // Update the dependent inner frame.
  self.innerFrameProcessor.width = outerFrameWidth + self.innerFrameWidth;
  [self setNeedsInnerFrameProcessing];

  // Update outer frame.
  [self setNeedsOuterFrameProcessing];
});

LTProxyCustomProperty(CGFloat, outerFrameSpread, OuterFrameSpread,
                      self.outerFrameProcessor, spread, Spread, ^{
  [self setNeedsOuterFrameProcessing];
});

LTProxyCustomProperty(CGFloat, outerFrameCorner, OuterFrameCorner,
                      self.outerFrameProcessor, corner, Corner, ^{
  [self setNeedsOuterFrameProcessing];
});

- (void)setOuterFrameNoise:(LTTexture *)outerFrameNoise {
  self.outerFrameProcessor.noise = outerFrameNoise;
}

- (LTTexture *)outerFrameNoise {
  return self.outerFrameProcessor.noise;
}

LTProxyCustomProperty(GLKVector3, outerFrameNoiseChannelMixer, OuterFrameNoiseChannelMixer,
                      self.outerFrameProcessor, noiseChannelMixer, NoiseChannelMixer, ^{
  [self setNeedsOuterFrameProcessing];
});

LTProxyCustomProperty(CGFloat, outerFrameNoiseAmplitude, OuterFrameNoiseAmplitude,
                      self.outerFrameProcessor, noiseAmplitude, NoiseAmplitude, ^{
  [self setNeedsOuterFrameProcessing];
});

LTProxyCustomProperty(GLKVector3, outerFrameColor, OuterFrameColor,
                      self.outerFrameProcessor, color, Color, ^{
  [self setNeedsOuterFrameProcessing];
});

#pragma mark -
#pragma mark Inner Frame
#pragma mark -

LTPropertyWithSetter(CGFloat, innerFrameWidth, InnerFrameWidth, 0, 25, 0, ^{
  LTParameterAssert(self.outerFrameWidth + innerFrameWidth <= self.innerFrameProcessor.maxWidth,
                    @"Sum of outer and inner width is above maximum value.");
  self.innerFrameProcessor.width = self.outerFrameWidth + innerFrameWidth;
  [self setNeedsInnerFrameProcessing];
});

LTProxyCustomProperty(CGFloat, innerFrameSpread, InnerFrameSpread,
                      self.innerFrameProcessor, spread, Spread, ^{
  [self setNeedsInnerFrameProcessing];
});

LTProxyCustomProperty(CGFloat, innerFrameCorner, InnerFrameCorner,
                      self.innerFrameProcessor, corner, Corner, ^{
  [self setNeedsInnerFrameProcessing];
});

- (void)setInnerFrameNoise:(LTTexture *)innerFrameNoise {
  self.innerFrameProcessor.noise = innerFrameNoise;
  [self setNeedsInnerFrameProcessing];
}

- (LTTexture *)innerFrameNoise {
  return self.innerFrameProcessor.noise;
}

LTProxyCustomProperty(GLKVector3, innerFrameNoiseChannelMixer, InnerFrameNoiseChannelMixer,
                      self.innerFrameProcessor, noiseChannelMixer, NoiseChannelMixer, ^{
  [self setNeedsInnerFrameProcessing];
});

LTProxyCustomProperty(CGFloat, innerFrameNoiseAmplitude, InnerFrameNoiseAmplitude,
                      self.innerFrameProcessor, noiseAmplitude, NoiseAmplitude, ^{
  [self setNeedsInnerFrameProcessing];
});

LTProxyCustomProperty(GLKVector3, innerFrameColor, InnerFrameColor,
                      self.innerFrameProcessor, color, Color, ^{
  [self setNeedsInnerFrameProcessing];
});

@end
