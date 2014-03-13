// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTBWTonalityProcessor.h"
#import "LTCGExtensions.h"
#import "LTColorGradient.h"
#import "LTGLKitExtensions.h"
#import "LTProceduralVignetting.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralFrame.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWProcessorFsh.h"
#import "LTShaderStorage+LTBWProcessorVsh.h"
#import "LTTexture+Factory.h"

@interface LTGPUImageProcessor ()
@property (strong, nonatomic) NSDictionary *auxiliaryTextures;
@end

@interface LTBWProcessor ()

@property (strong, nonatomic) LTBWTonalityProcessor *toneProcessor;
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;
@property (strong, nonatomic) LTProceduralFrame *wideFrameProcessor;
@property (strong, nonatomic) LTProceduralFrame *narrowFrameProcessor;

@end

@implementation LTBWProcessor

@synthesize grainTexture = _grainTexture;
@synthesize wideFrameNoise = _wideFrameNoise;
@synthesize narrowFrameNoise = _narrowFrameNoise;

static const CGFloat kVignettingMaxDimension = 256;
static const CGFloat kFrameMaxDimension = 1024;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTProgram *program = [[LTProgram alloc] initWithVertexSource:[LTBWProcessorVsh source]
                                                fragmentSource:[LTBWProcessorFsh source]];
  
  // Setup noise.
  LTTexture *noise = [LTTexture textureWithImage:LTLoadMat([self class], @"TiledNoise.png")];
  noise.wrap = LTTextureWrapRepeat;
  
  // Setup tonality.
  LTTexture *toneTexture = [LTTexture textureWithPropertiesOf:output];
  self.toneProcessor = [[LTBWTonalityProcessor alloc] initWithInput:input output:toneTexture];
  [self.toneProcessor process];
  
  // Setup vignetting.
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  [self.vignetteProcessor process];
  
  // Setup wide frame.
  LTTexture *wideFrameTexture = [self createFrameTextureWithInput:input];
  self.wideFrameProcessor = [[LTProceduralFrame alloc] initWithOutput:wideFrameTexture];
  [self.wideFrameProcessor process];
  
  // Setup narrow frame.
  LTTexture *narrowFrameTexture = [self createFrameTextureWithInput:input];
  self.narrowFrameProcessor = [[LTProceduralFrame alloc] initWithOutput:narrowFrameTexture];
  [self.narrowFrameProcessor process];
  
  NSDictionary *auxiliaryTextures =
      @{[LTBWProcessorFsh grainTexture]: self.grainTexture,
        [LTBWProcessorFsh vignettingTexture]: vignetteTexture,
        [LTBWProcessorFsh wideFrameTexture]: wideFrameTexture,
        [LTBWProcessorFsh narrowFrameTexture]: narrowFrameTexture};
  if (self = [super initWithProgram:program sourceTexture:toneTexture
                  auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setupGrainTextureScalingWith:input grain:noise];
    [self setDefaultValues];
  }
  return self;
}

- (void)setDefaultValues {
  self.grainAmplitude = kDefaultGrainAmplitude;
  self[@"grainChannelMixer"] = $(GLKVector3Make(1.0, 0.0, 0.0));
  self[@"vignetteColor"] = $(GLKVector3Make(0.0, 0.0, 0.0));
}

- (void)setupGrainTextureScalingWith:(LTTexture *)input grain:(LTTexture *)grain {
  CGFloat xScale = input.size.width / grain.size.width;
  CGFloat yScale = input.size.height / grain.size.height;
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
  return [LTTexture textureWithImage:input];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

// Tone.

- (void)setColorFilter:(GLKVector3)colorFilter {
  _colorFilter = colorFilter;
  self.toneProcessor.colorFilter = colorFilter;
  [self.toneProcessor process];
}

- (void)setBrightness:(CGFloat)brightness {
  _brightness = brightness;
  self.toneProcessor.brightness = brightness;
  [self.toneProcessor process];
}

- (void)setContrast:(CGFloat)contrast {
  _contrast = contrast;
  self.toneProcessor.contrast = contrast;
  [self.toneProcessor process];
}

- (void)setExposure:(CGFloat)exposure {
  _exposure = exposure;
  self.toneProcessor.exposure = exposure;
  [self.toneProcessor process];
}

- (void)setStructure:(CGFloat)structure {
  _structure = structure;
  self.toneProcessor.structure = structure;
  [self.toneProcessor process];
}

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  _colorGradientTexture = colorGradientTexture;
  self.toneProcessor.colorGradientTexture = colorGradientTexture;
  [self.toneProcessor process];
}

// Vignetting.

- (void)setVignetteColor:(GLKVector3)vignetteColor {
  LTParameterAssert(GLKVectorInRange(vignetteColor, 0.0, 1.0), @"Color filter is out of range.");

  _vignetteColor = vignetteColor;
  self[@"vignetteColor"] = $(vignetteColor);
  [self.vignetteProcessor process];
}

- (void)setVignettingSpread:(CGFloat)vignettingSpread {
  _vignettingSpread = vignettingSpread;
  self.vignetteProcessor.spread = vignettingSpread;
  [self.vignetteProcessor process];
}

- (void)setVignettingCorner:(CGFloat)vignettingCorner {
  _vignettingCorner = vignettingCorner;
  self.vignetteProcessor.corner = vignettingCorner;
  [self.vignetteProcessor process];
}

- (void)setVignettingNoise:(LTTexture *)vignettingNoise {
  _vignettingNoise = vignettingNoise;
  self.vignetteProcessor.noise = vignettingNoise;
  [self.vignetteProcessor process];
}

- (void)setVignettingNoiseChannelMixer:(GLKVector3)vignettingNoiseChannelMixer {
  _vignettingNoiseChannelMixer = vignettingNoiseChannelMixer;
  self.vignetteProcessor.noiseChannelMixer = vignettingNoiseChannelMixer;
  [self.vignetteProcessor process];
}

- (void)setVignettingNoiseAmplitude:(CGFloat)vignettingNoiseAmplitude {
  _vignettingNoiseAmplitude = vignettingNoiseAmplitude;
  self.vignetteProcessor.noiseAmplitude = vignettingNoiseAmplitude;
  [self.vignetteProcessor process];
}

// Grain.

- (LTTexture *)grainTexture {
  if (!_grainTexture) {
    _grainTexture = [self createNeutralNoise];
  }
  return _grainTexture;
}

- (void)setGrainTexture:(LTTexture *)grainTexture {
  // Update details LUT texture in auxiliary textures.
  _grainTexture = grainTexture;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = grainTexture;
  self.auxiliaryTextures = auxiliaryTextures;
  [self process];
}

-(void)setGrainChannelMixer:(GLKVector3)grainChannelMixer {
  _grainChannelMixer = grainChannelMixer / std::sum(grainChannelMixer);
  self[@"grainChannelMixer"] = $(_grainChannelMixer);
  [self process];
}

LTBoundedPrimitivePropertyImplementWithCustomSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 100,
    0, ^{
  _grainAmplitude = grainAmplitude;
  self[@"grainAmplitude"] = @(grainAmplitude);
  [self process];
});

// Wide Frame.

- (void)setWideFrameWidth:(CGFloat)wideFrameWidth {
  _wideFrameWidth = wideFrameWidth;
  self.wideFrameProcessor.width = wideFrameWidth;
  [self.wideFrameProcessor process];
}

- (void)setWideFrameSpread:(CGFloat)wideFrameSpread {
  _wideFrameSpread = wideFrameSpread;
  self.wideFrameProcessor.spread = wideFrameSpread;
  [self.wideFrameProcessor process];
}

- (void)setWideFrameCorner:(CGFloat)wideFrameCorner {
  _wideFrameCorner = wideFrameCorner;
  self.wideFrameProcessor.corner = wideFrameCorner;
  [self.wideFrameProcessor process];
}

- (LTTexture *)wideFrameNoise {
  if (!_wideFrameNoise) {
    _wideFrameNoise = [self createNeutralNoise];
  }
  return _wideFrameNoise;
}

- (void)setWideFrameNoise:(LTTexture *)wideFrameNoise {
  // Update details LUT texture in auxiliary textures.
  _wideFrameNoise = wideFrameNoise;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = wideFrameNoise;
  self.auxiliaryTextures = auxiliaryTextures;
  [self process];
}

- (void)setWideFrameNoiseChannelMixer:(GLKVector3)wideFrameNoiseChannelMixer {
  _wideFrameNoiseChannelMixer = wideFrameNoiseChannelMixer;
  self.wideFrameProcessor.noiseChannelMixer = wideFrameNoiseChannelMixer;
  [self.wideFrameProcessor process];
}

- (void)setWideFrameNoiseAmplitude:(CGFloat)wideFrameNoiseAmplitude {
  _wideFrameNoiseAmplitude = wideFrameNoiseAmplitude;
  self.wideFrameProcessor.noiseAmplitude = wideFrameNoiseAmplitude;
  [self.wideFrameProcessor process];
}

- (void)setWideFrameColor:(GLKVector3)wideFrameColor {
  _wideFrameColor = wideFrameColor;
  self.wideFrameProcessor.color = wideFrameColor;
  [self.wideFrameProcessor process];
}

// Narrow Frame.

- (void)setNarrowFrameWidth:(CGFloat)narrowFrameWidth {
  _narrowFrameWidth = narrowFrameWidth;
  self.narrowFrameProcessor.width = narrowFrameWidth;
  [self.narrowFrameProcessor process];
}

- (void)setNarrowFrameSpread:(CGFloat)narrowFrameSpread {
  _narrowFrameSpread = narrowFrameSpread;
  self.narrowFrameProcessor.spread = narrowFrameSpread;
  [self.narrowFrameProcessor process];
}

- (void)setNarrowFrameCorner:(CGFloat)narrowFrameCorner {
  _narrowFrameCorner = narrowFrameCorner;
  self.narrowFrameProcessor.corner = narrowFrameCorner;
  [self.narrowFrameProcessor process];
}

- (void)setNarrowFrameNoise:(LTTexture *)narrowFrameNoise {
  // Update details LUT texture in auxiliary textures.
  _narrowFrameNoise = narrowFrameNoise;
  NSMutableDictionary *auxiliaryTextures = [self.auxiliaryTextures mutableCopy];
  auxiliaryTextures[[LTBWProcessorFsh grainTexture]] = narrowFrameNoise;
  self.auxiliaryTextures = auxiliaryTextures;
  [self process];
}

- (void)setNarrowFrameNoiseChannelMixer:(GLKVector3)narrowFrameNoiseChannelMixer {
  _narrowFrameNoiseChannelMixer = narrowFrameNoiseChannelMixer;
  self.narrowFrameProcessor.noiseChannelMixer = narrowFrameNoiseChannelMixer;
  [self.narrowFrameProcessor process];
}

- (void)setNarrowFrameNoiseAmplitude:(CGFloat)narrowFrameNoiseAmplitude {
  _narrowFrameNoiseAmplitude = narrowFrameNoiseAmplitude;
  self.narrowFrameProcessor.noiseAmplitude = narrowFrameNoiseAmplitude;
  [self.narrowFrameProcessor process];
}

- (void)setNarrowFrameColor:(GLKVector3)narrowFrameColor {
  _narrowFrameColor = narrowFrameColor;
  self.narrowFrameProcessor.color = narrowFrameColor;
  [self.narrowFrameProcessor process];
}

@end
