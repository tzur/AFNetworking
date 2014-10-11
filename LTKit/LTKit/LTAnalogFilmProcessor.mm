// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTCLAHEProcessor.h"
#import "LTColorConversionProcessor.h"
#import "LTColorGradient.h"
#import "LTCurve.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTAnalogFilmFsh.h"
#import "LTShaderStorage+LTAnalogFilmVsh.h"
#import "LTTexture+Factory.h"

@interface LTAnalogFilmProcessor ()

/// Processor for generating the vignette texture.
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;

/// If \c YES, the vignette processor should run at the next processing round of this processor.
@property (nonatomic) BOOL vignetteProcessorInputChanged;

/// RGBA texture with one row and 256 columns that defines greyscale to color mapping. RGB part of
/// this LUT is the current color gradient mapping which adds tint to the image. Alpha channel holds
/// the tone mapping curve. Default value is an identity mapping across the channels.
@property (strong, nonatomic) LTTexture *colorGradientTexture;

/// Mat that stores color gradient in rgb channels. Alpha channel is unused.
@property (nonatomic) cv::Mat4b colorGradientMat;

/// Tone mapping curve that encapsulates brightness, contrast, exposure and offset adjustments.
@property (nonatomic) cv::Mat1b toneCurveMat;

/// The generation id of the input texture that was used to create the current details textures.
@property (nonatomic) NSUInteger detailsTextureGenerationID;

@end

@implementation LTAnalogFilmProcessor

@synthesize grainTexture = _grainTexture;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  NSDictionary *auxiliaryTextures =
      @{[LTAnalogFilmFsh colorGradientTexture]:
          [[self defaultColorGradient] textureWithSamplingPoints:256],
        [LTAnalogFilmFsh grainTexture]: [self defaultGrainTexture],
        [LTAnalogFilmFsh vignettingTexture]: vignetteTexture,
        [LTAnalogFilmFsh assetTexture]: [self defaultAssetTexture]};
  if (self = [super initWithVertexSource:[LTAnalogFilmVsh source]
                          fragmentSource:[LTAnalogFilmFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    self[[LTAnalogFilmFsh aspectRatio]] = @([self aspectRatio]);
    [self resetInputModel];
  }
  return self;
}

- (LTColorGradient *)defaultColorGradient {
  return [LTColorGradient identityGradient];
}

- (LTTexture *)defaultGrainTexture {
  LTTexture *greyTexture = [self greyTexture];
  greyTexture.wrap = LTTextureWrapRepeat;
  return greyTexture;
}

// Grey texture is neutral in overlay blending mode.
- (LTTexture *)greyTexture {
  LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(2, 2)];
  [greyTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
  return greyTexture;
}

- (LTTexture *)defaultAssetTexture {
  LTTexture *assetTexture = [LTTexture byteRGBATextureWithSize:CGSizeMake(2048, 2048)];
  [assetTexture clearWithColor:LTVector4(0.0, 0.0, 0.0, 0.5)];
  return assetTexture;
}

- (LTTexture *)createVignettingTextureWithInput:(LTTexture *)input {
  static const CGFloat kVignettingMaxDimension = 256;
  CGSize vignettingSize = CGScaleDownToDimension(input.size, kVignettingMaxDimension);
  LTTexture *vignetteTexture = [LTTexture byteRedTextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (void)updateDetailsTextureIfNecessary {
  if (self.detailsTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTAnalogFilmFsh detailsTexture]]) {
    self.detailsTextureGenerationID = self.inputTexture.generationID;
    [self setAuxiliaryTexture:[self createDetailsTexture:self.inputTexture]
                     withName:[LTAnalogFilmFsh detailsTexture]];
  }
}

- (LTTexture *)createDetailsTexture:(LTTexture *)inputTexture {
  LTTexture *detailsTexture = [LTTexture byteRedTextureWithSize:inputTexture.size];
  LTCLAHEProcessor *processor = [[LTCLAHEProcessor alloc] initWithInputTexture:self.inputTexture
                                                                 outputTexture:detailsTexture];
  [processor process];
  return detailsTexture;
}

#pragma mark -
#pragma mark Input model
#pragma mark -

- (CGFloat)aspectRatio {
  return self.inputSize.width / self.inputSize.height;
}

+ (NSSet *)inputModelPropertyKeys {
  static NSSet *properties;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    properties = [NSSet setWithArray:@[
      @instanceKeypath(LTAnalogFilmProcessor, brightness),
      @instanceKeypath(LTAnalogFilmProcessor, contrast),
      @instanceKeypath(LTAnalogFilmProcessor, exposure),
      @instanceKeypath(LTAnalogFilmProcessor, offset),
      @instanceKeypath(LTAnalogFilmProcessor, structure),
      @instanceKeypath(LTAnalogFilmProcessor, saturation),
       
      @instanceKeypath(LTAnalogFilmProcessor, colorGradient),
      @instanceKeypath(LTAnalogFilmProcessor, colorGradientIntensity),
      @instanceKeypath(LTAnalogFilmProcessor, colorGradientFade),
       
      @instanceKeypath(LTAnalogFilmProcessor, grainTexture),
      @instanceKeypath(LTAnalogFilmProcessor, grainChannelMixer),
      @instanceKeypath(LTAnalogFilmProcessor, grainAmplitude),
       
      @instanceKeypath(LTAnalogFilmProcessor, vignetteIntensity),
      @instanceKeypath(LTAnalogFilmProcessor, vignetteSpread),
      @instanceKeypath(LTAnalogFilmProcessor, vignetteCorner),
      
      @instanceKeypath(LTAnalogFilmProcessor, assetTexture),
      @instanceKeypath(LTAnalogFilmProcessor, lightLeakIntensity),
      @instanceKeypath(LTAnalogFilmProcessor, grungeIntensity)
    ]];
  });
  
  return properties;
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
  [self updateDetailsTextureIfNecessary];
  
  [self runSubProcessors];
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
  self[[LTAnalogFilmFsh structure]] = @(structure);
}

LTPropertyWithoutSetter(CGFloat, saturation, Saturation, -1, 1, 0);
- (void)setSaturation:(CGFloat)saturation {
  [self _verifyAndSetSaturation:saturation];
  // Remap [-1, 0] -> [0, 1] and [0, 1] to [1, 2.5].
  static const CGFloat kSaturationScaling = 1.5;
  CGFloat remap = saturation < 0 ? saturation + 1 : 1 + saturation * kSaturationScaling;
  self[[LTAnalogFilmFsh saturation]] = @(remap);
}

#pragma mark -
#pragma mark Color Gradient
#pragma mark -

- (void)setColorGradient:(LTColorGradient *)colorGradient {
  _colorGradient = colorGradient;
  self.colorGradientTexture = [colorGradient textureWithSamplingPoints:256];
}

- (void)setColorGradientTexture:(LTTexture *)colorGradientTexture {
  _colorGradientTexture = colorGradientTexture;
  self.colorGradientMat = [_colorGradientTexture image];
  [self setAuxiliaryTexture:self.colorGradientTexture
                   withName:[LTAnalogFilmFsh colorGradientTexture]];
  [self updateCurve];
}

LTPropertyWithoutSetter(CGFloat, colorGradientIntensity, ColorGradientIntensity, 0, 1, 0);
- (void)setColorGradientIntensity:(CGFloat)colorGradientIntensity {
  [self _verifyAndSetColorGradientIntensity:colorGradientIntensity];
  self[[LTAnalogFilmFsh colorGradientIntensity]] = @(colorGradientIntensity);
}

LTPropertyWithoutSetter(CGFloat, colorGradientFade, ColorGradientFade, 0, 1, 0);
- (void)setColorGradientFade:(CGFloat)colorGradientFade {
  [self _verifyAndSetColorGradientFade:colorGradientFade];
  self[[LTAnalogFilmFsh colorGradientFade]] = @(colorGradientFade);
}

#pragma mark -
#pragma mark Curve
#pragma mark -

- (void)updateToneLUT {
  static const ushort kLutSize = 256;
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
          (1.0 - brightness) * [LTCurve identity] + brightness * brightnessCurve,
          toneCurve);
  self.toneCurveMat = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;
  
  [self updateCurve];
}

/// Updates curve, by combining color gradient and tone curve. The reason for merging is to use less
/// texture units.
- (void)updateCurve {
  [self.colorGradientTexture mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::Mat mixIn[] = {self.colorGradientMat, self.toneCurveMat};
    int fromTo[] = {0, 0, 1, 1, 2, 2, 4, 3};
  
    cv::mixChannels(mixIn, 2, mapped, 1, fromTo, 4);
  }];
}

#pragma mark -
#pragma mark Vignette
#pragma mark -

LTPropertyWithoutSetter(CGFloat, vignetteIntensity, VignetteIntensity, -1, 1, 0);
- (void)setVignetteIntensity:(CGFloat)vignetteIntensity {
  [self _verifyAndSetVignetteIntensity:vignetteIntensity];
  // // Remap [-1, 1] -> [0.0 1.0].
  CGFloat remap = (1.0 + vignetteIntensity) / 2.0;
  self[[LTAnalogFilmFsh vignetteIntensity]] = @(remap);
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

#pragma mark -
#pragma mark Grain
#pragma mark -

- (LTTexture *)grainTexture {
  if (!_grainTexture) {
    _grainTexture = [self greyTexture];
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

- (void)setupGrainTextureScalingWithOutputSize:(CGSize)size grain:(LTTexture *)grain {
  self[[LTAnalogFilmVsh grainScaling]] = $(LTVector2(size / grain.size));
}

LTPropertyWithoutSetter(LTVector3, grainChannelMixer, GrainChannelMixer,
                        LTVector3Zero, LTVector3One, LTVector3(1, 0, 0));
- (void)setGrainChannelMixer:(LTVector3)grainChannelMixer {
  [self _verifyAndSetGrainChannelMixer:grainChannelMixer];
  _grainChannelMixer = grainChannelMixer / grainChannelMixer.sum();
  self[[LTAnalogFilmFsh grainChannelMixer]] = $(_grainChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 1, 1);
- (void)setGrainAmplitude:(CGFloat)grainAmplitude {
  [self _verifyAndSetGrainAmplitude:grainAmplitude];
  self[[LTAnalogFilmFsh grainAmplitude]] = @(grainAmplitude);
}

#pragma mark -
#pragma mark Asset Texture
#pragma mark -

LTPropertyWithoutSetter(CGFloat, lightLeakIntensity, LightLeakIntensity, 0, 1, 0);
- (void)setLightLeakIntensity:(CGFloat)lightLeakIntensity {
  [self _verifyAndSetLightLeakIntensity:lightLeakIntensity];
  self[[LTAnalogFilmFsh lightLeakIntensity]] = @(lightLeakIntensity);
}

- (void)setAssetTexture:(LTTexture *)assetTexture {
  if (!assetTexture) {
    assetTexture = [self defaultAssetTexture];
  }
  LTParameterAssert([self isValidTexture:assetTexture], @"Asset texture should be 2048x2048.");
  _assetTexture = assetTexture;
  [self setAuxiliaryTexture:assetTexture withName:[LTAnalogFilmFsh assetTexture]];
}

- (BOOL)isValidTexture:(LTTexture *)texture {
  BOOL squareRatio = (texture.size.width == texture.size.height);
  BOOL correctSize = (texture.size.width == 2048);
  return squareRatio && correctSize;
}

LTPropertyWithoutSetter(CGFloat, grungeIntensity, GrungeIntensity, 0, 1, 0);
- (void)setGrungeIntensity:(CGFloat)grungeIntensity {
  [self _verifyAndSetGrungeIntensity:grungeIntensity];
  self[[LTAnalogFilmFsh grungeIntensity]] = @(grungeIntensity);
}

@end
