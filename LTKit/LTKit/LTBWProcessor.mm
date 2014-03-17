// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTBWTonalityProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralFrame.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWProcessorFsh.h"
#import "LTShaderStorage+LTBWProcessorVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTBWProcessor ()

@property (nonatomic) BOOL subProcessorsInitialized;
@property (strong, nonatomic) LTBWTonalityProcessor *toneProcessor;
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;
@property (strong, nonatomic) LTProceduralFrame *outerFrameProcessor;
@property (strong, nonatomic) LTProceduralFrame *innerFrameProcessor;
@property (nonatomic) CGSize outputSize;

@end

@implementation LTBWProcessor

@synthesize grainTexture = _grainTexture;
@synthesize outerFrameNoise = _outerFrameNoise;
@synthesize innerFrameNoise = _innerFrameNoise;

static const CGFloat kVignettingMaxDimension = 256;
static const CGFloat kFrameMaxDimension = 1024;
static const GLKVector3 kDefaultVignettingColor = GLKVector3Make(0.0, 0.0, 0.0);
// Unlike in LTProceduralVignetting class, the default spread here is 0, so no vignetting is seen by
// default.
static const CGFloat kDefaultVignettingSpread = 0;
static const GLKVector3 kDefaultGrainChannelMixer = GLKVector3Make(1.0, 0.0, 0.0);

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
  self.outerFrameProcessor = [[LTProceduralFrame alloc] initWithOutput:outerFrameTexture];
  
  // Setup narrow frame.
  LTTexture *innerFrameTexture = [self createFrameTextureWithInput:input];
  self.innerFrameProcessor = [[LTProceduralFrame alloc] initWithOutput:innerFrameTexture];
  
  NSDictionary *auxiliaryTextures =
      @{[LTBWProcessorFsh grainTexture]: self.grainTexture,
        [LTBWProcessorFsh vignettingTexture]: vignetteTexture,
        [LTBWProcessorFsh outerFrameTexture]: outerFrameTexture,
        [LTBWProcessorFsh innerFrameTexture]: innerFrameTexture};
  if (self = [super initWithProgram:program sourceTexture:toneTexture
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
    _outputSize = output.size;
    _subProcessorsInitialized = NO;
  }
  return self;
}

- (void)setDefaultValues {
  // New properties introduced by LTBWProcessor.
  _grainAmplitude = kDefaultGrainAmplitude;
  _grainChannelMixer = kDefaultGrainChannelMixer;
  self[@"grainChannelMixer"] = $(self.grainChannelMixer);
  _vignetteColor = kDefaultVignettingColor;
  self[@"vignetteColor"] = $(self.vignetteColor);
  // Existing properties that LTBWProcessor mirrors from other processors.
  self.vignettingSpread = kDefaultVignettingSpread;
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

- (LTTexture *)createFrameTextureWithInput:(LTTexture *)input {
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

- (void)initializeSubProcessors {
  [self.toneProcessor process];
  [self.vignetteProcessor process];
  [self.outerFrameProcessor process];
  [self.innerFrameProcessor process];
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

- (void)setColorFilter:(GLKVector3)colorFilter {
  self.toneProcessor.colorFilter = colorFilter;
  [self.toneProcessor process];
}

- (GLKVector3)colorFilter {
  return self.toneProcessor.colorFilter;
}

- (void)setBrightness:(CGFloat)brightness {
  self.toneProcessor.brightness = brightness;
  [self.toneProcessor process];
}

- (CGFloat)brightness {
  return self.toneProcessor.brightness;
}

- (void)setContrast:(CGFloat)contrast {
  self.toneProcessor.contrast = contrast;
  [self.toneProcessor process];
}

- (CGFloat)contrast {
  return self.toneProcessor.contrast;
}

- (void)setExposure:(CGFloat)exposure {
  self.toneProcessor.exposure = exposure;
  [self.toneProcessor process];
}

- (CGFloat)exposure {
  return self.toneProcessor.exposure;
}

- (void)setStructure:(CGFloat)structure {
  self.toneProcessor.structure = structure;
  [self.toneProcessor process];
}

- (CGFloat)structure {
  return self.toneProcessor.structure;
}

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  self.toneProcessor.colorGradientTexture = colorGradientTexture;
  [self.toneProcessor process];
}

- (LTTexture *)colorGradientTexture {
  return self.toneProcessor.colorGradientTexture;
}

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
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = grainTexture;
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

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 100,
    1, ^{
  _grainAmplitude = grainAmplitude;
  self[@"grainAmplitude"] = @(grainAmplitude);
  [self process];
});

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

- (void)setOuterFrameWidth:(CGFloat)outerFrameWidth {
  self.outerFrameProcessor.width = outerFrameWidth;
  [self.outerFrameProcessor process];
}

- (CGFloat)outerFrameWidth {
  return self.outerFrameProcessor.width;
}

- (void)setOuterFrameSpread:(CGFloat)outerFrameSpread {
  self.outerFrameProcessor.spread = outerFrameSpread;
  [self.outerFrameProcessor process];
}

- (CGFloat)outerFrameSpread {
  return self.outerFrameProcessor.spread;
}

- (void)setOuterFrameCorner:(CGFloat)outerFrameCorner {
  self.outerFrameProcessor.corner = outerFrameCorner;
  [self.outerFrameProcessor process];
}

- (CGFloat)outerFrameCorner {
  return self.outerFrameProcessor.corner;
}

- (void)setOuterFrameNoise:(LTTexture *)outerFrameNoise {
  // Update details LUT texture in auxiliary textures.
  _outerFrameNoise = outerFrameNoise;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = outerFrameNoise;
  self.auxiliaryTextures = auxiliaryTextures;
  [self process];
}

- (LTTexture *)outerFrameNoise {
  if (!_outerFrameNoise) {
    _outerFrameNoise = [self createNeutralNoise];
  }
  return _outerFrameNoise;
}

- (void)setOuterFrameNoiseChannelMixer:(GLKVector3)outerFrameNoiseChannelMixer {
  self.outerFrameProcessor.noiseChannelMixer = outerFrameNoiseChannelMixer;
  [self.outerFrameProcessor process];
}

- (GLKVector3)outerFrameNoiseChannelMixer {
  return self.outerFrameProcessor.noiseChannelMixer;
}

- (void)setOuterFrameNoiseAmplitude:(CGFloat)outerFrameNoiseAmplitude {
  self.outerFrameProcessor.noiseAmplitude = outerFrameNoiseAmplitude;
  [self.outerFrameProcessor process];
}

- (CGFloat)outerFrameNoiseAmplitude {
  return self.outerFrameProcessor.noiseAmplitude;
}

- (void)setOuterFrameColor:(GLKVector3)outerFrameColor {
  self.outerFrameProcessor.color = outerFrameColor;
  [self.outerFrameProcessor process];
}

- (GLKVector3)outerFrameColor {
  return self.outerFrameProcessor.color;
}

#pragma mark -
#pragma mark Inner Frame
#pragma mark -

- (void)setInnerFrameWidth:(CGFloat)innerFrameWidth {
  LTParameterAssert(self.outerFrameWidth + innerFrameWidth <= self.innerFrameProcessor.maxWidth,
                    @"Sum of outer and inner width is above maximum value.");
  _innerFrameWidth = self.outerFrameWidth + innerFrameWidth;
  self.innerFrameProcessor.width = _innerFrameWidth;
  [self.innerFrameProcessor process];
}

- (void)setInnerFrameSpread:(CGFloat)innerFrameSpread {
  self.innerFrameProcessor.spread = innerFrameSpread;
  [self.innerFrameProcessor process];
}

- (CGFloat)innerFrameSpread {
  return self.innerFrameProcessor.spread;
}

- (void)setInnerFrameCorner:(CGFloat)innerFrameCorner {
  self.innerFrameProcessor.corner = innerFrameCorner;
  [self.innerFrameProcessor process];
}

- (CGFloat)innerFrameCorner {
  return self.innerFrameProcessor.corner;
}

- (void)setInnerFrameNoise:(LTTexture *)innerFrameNoise {
  // Update details LUT texture in auxiliary textures.
  _innerFrameNoise = innerFrameNoise;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = innerFrameNoise;
  self.auxiliaryTextures = auxiliaryTextures;
  [self process];
}

- (LTTexture *)innerFrameNoise {
  if (!_innerFrameNoise) {
    _innerFrameNoise = [self createNeutralNoise];
  }
  return _innerFrameNoise;
}

- (void)setInnerFrameNoiseChannelMixer:(GLKVector3)innerFrameNoiseChannelMixer {
  self.innerFrameProcessor.noiseChannelMixer = innerFrameNoiseChannelMixer;
  [self.innerFrameProcessor process];
}

- (GLKVector3)innerFrameNoiseChannelMixer {
  return self.innerFrameProcessor.noiseChannelMixer;
}

- (void)setInnerFrameNoiseAmplitude:(CGFloat)innerFrameNoiseAmplitude {
  self.innerFrameProcessor.noiseAmplitude = innerFrameNoiseAmplitude;
  [self.innerFrameProcessor process];
}

- (CGFloat)innerFrameNoiseAmplitude {
  return self.innerFrameProcessor.noiseAmplitude;
}

- (void)setInnerFrameColor:(GLKVector3)innerFrameColor {
  self.innerFrameProcessor.color = innerFrameColor;
  [self.innerFrameProcessor process];
}

- (GLKVector3)innerFrameColor {
  return self.innerFrameProcessor.color;
}

@end
