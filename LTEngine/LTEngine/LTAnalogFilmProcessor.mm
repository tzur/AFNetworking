// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTAnalogFilmProcessor.h"

#import "LTCLAHEProcessor.h"
#import "LTColorConversionProcessor.h"
#import "LTColorGradient.h"
#import "LTCurve.h"
#import "LTGLKitExtensions.h"
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

/// RGBA textures with one row and 256 columns that defines greyscale to color mapping. RGB part of
/// these LUT is the current color gradient mapping which adds tint to the image. Alpha channel
/// holds the tone mapping curve. Default value is an identity mapping across the channels. Two
/// textures are used for ping-pong rendering that improves the performance.

/// First color gradient texture.
@property (strong, nonatomic) LTTexture *colorGradientTextureA;

/// Second color gradient texture.
@property (strong, nonatomic) LTTexture *colorGradientTextureB;

/// If \c YES, \c colorGradientTextureB will be used during the next rendering pass,
/// \c colorGradientTextureA otherwise.
@property (nonatomic) BOOL shouldUseColorGradientTextureB;

/// If \c YES, tone LUT update should run at the next processing round of this processor.
@property (nonatomic) BOOL shouldUpdateToneLUT;

/// The generation id of the input texture that was used to create the current details textures.
@property (nonatomic) id detailsTextureGenerationID;

@end

@implementation LTAnalogFilmProcessor

@synthesize grainTexture = _grainTexture;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  NSDictionary *auxiliaryTextures =
      @{[LTAnalogFilmFsh vignettingTexture]: vignetteTexture,
        [LTAnalogFilmFsh grainTexture]: [self defaultGrainTexture],
        [LTAnalogFilmFsh assetTexture]: [self defaultAssetTexture]};
  if (self = [super initWithVertexSource:[LTAnalogFilmVsh source]
                          fragmentSource:[LTAnalogFilmFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures
                               andOutput:output]) {
    self[[LTAnalogFilmFsh aspectRatio]] = @([self aspectRatio]);
    [self createColorGradientTextures];
    [self resetInputModel];
  }
  return self;
}

- (void)createColorGradientTextures {
  self.colorGradientTextureA = [[self defaultColorGradient] textureWithSamplingPoints:256];
  self.colorGradientTextureB = [[self defaultColorGradient] textureWithSamplingPoints:256];
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
  LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:CGSizeMakeUniform(1)];
  [greyTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
  return greyTexture;
}

- (LTTexture *)defaultAssetTexture {
  LTTexture *assetTexture = [LTTexture byteRGBATextureWithSize:CGSizeMakeUniform(1)];
  [assetTexture clearWithColor:LTVector4(0.0, 0.0, 0.0, 0.5)];
  return assetTexture;
}

- (LTLightLeakRotation)defaultLightLeakRotation {
  return LTLightLeakRotation0;
}

- (LTTexture *)createVignettingTextureWithInput:(LTTexture *)input {
  static const CGFloat kVignettingMaxDimension = 256;
  CGSize vignettingSize = CGScaleDownToDimension(input.size, kVignettingMaxDimension);
  LTTexture *vignetteTexture = [LTTexture byteRedTextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (void)updateDetailsTextureIfNecessary {
  if ([self.detailsTextureGenerationID isEqual:self.inputTexture.generationID] &&
      self.auxiliaryTextures[[LTAnalogFilmFsh detailsTexture]]) {
    return;
  }

  self.detailsTextureGenerationID = self.inputTexture.generationID;
  [self setAuxiliaryTexture:[self createDetailsTexture:self.inputTexture]
                   withName:[LTAnalogFilmFsh detailsTexture]];
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
      @instanceKeypath(LTAnalogFilmProcessor, vignetteTransition),
      
      @instanceKeypath(LTAnalogFilmProcessor, assetTexture),
      @instanceKeypath(LTAnalogFilmProcessor, lightLeakIntensity),
      @instanceKeypath(LTAnalogFilmProcessor, lightLeakRotation),
      @instanceKeypath(LTAnalogFilmProcessor, frameWidth)
    ]];
  });
  
  return properties;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [self updateDetailsTextureIfNecessary];

  [self runSubProcessors];
  [self updateLUTs];
}

- (void)runSubProcessors {
  if (self.vignetteProcessorInputChanged) {
    [self.vignetteProcessor process];
    self.vignetteProcessorInputChanged = NO;
  }
}

- (void)setNeedsToneLUTUpdate {
  self.shouldUpdateToneLUT = YES;
}

- (void)setNeedsVignetteProcessing {
  self.vignetteProcessorInputChanged = YES;
}

- (void)updateLUTs {
  if (self.shouldUpdateToneLUT) {
    [self updateToneLUT];
    self.shouldUpdateToneLUT = NO;
  }
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyWithoutSetter(CGFloat, brightness, Brightness, -1, 1, 0);
- (void)setBrightness:(CGFloat)brightness {
  [self _verifyAndSetBrightness:brightness];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, contrast, Contrast, -1, 1, 0);
- (void)setContrast:(CGFloat)contrast {
  [self _verifyAndSetContrast:contrast];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, exposure, Exposure, -1, 1, 0);
- (void)setExposure:(CGFloat)exposure {
  [self _verifyAndSetExposure:exposure];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, offset, Offset, -1, 1, 0);
- (void)setOffset:(CGFloat)offset {
  [self _verifyAndSetOffset:offset];
  [self setNeedsToneLUTUpdate];
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
  [self setNeedsToneLUTUpdate];
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
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;

  LTTexture *target = self.shouldUseColorGradientTextureB ?
      self.colorGradientTextureB : self.colorGradientTextureA;
  [target mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::Mat mixIn[] = {[self.colorGradient matWithSamplingPoints:256], toneCurve};
    int fromTo[] = {0, 0, 1, 1, 2, 2, 4, 3};

    cv::mixChannels(mixIn, 2, mapped, 1, fromTo, 4);
  }];
  [self setAuxiliaryTexture:target withName:[LTAnalogFilmFsh colorGradientTexture]];

  self.shouldUseColorGradientTextureB = !self.shouldUseColorGradientTextureB;
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

LTPropertyProxyWithoutSetter(CGFloat, vignetteTransition, VignetteTransition,
                             self.vignetteProcessor, transition, Transition);
- (void)setVignetteTransition:(CGFloat)vignetteTransition {
  self.vignetteProcessor.transition = vignetteTransition;
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
                        LTVector3::zeros(), LTVector3::ones(), LTVector3(1, 0, 0));
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
  LTParameterAssert([self isValidTexture:assetTexture],
                    @"Asset should be a square, RGBA8 texture.");
  _assetTexture = assetTexture;
  [self setAuxiliaryTexture:assetTexture withName:[LTAnalogFilmFsh assetTexture]];
}

- (BOOL)isValidTexture:(LTTexture *)texture {
  BOOL hasSquareRatio = (texture.size.width == texture.size.height);
  BOOL hasCorrectPixelFormat = (texture.pixelFormat.value == LTGLPixelFormatRGBA8Unorm);
  return hasSquareRatio && hasCorrectPixelFormat;
}

LTPropertyWithoutSetter(CGFloat, frameWidth, FrameWidth, -1, 1, 0);
- (void)setFrameWidth:(CGFloat)frameWidth {
  [self _verifyAndSetFrameWidth:frameWidth];
  self[[LTAnalogFilmFsh frameWidth]] = $([self remapFrameWidth:frameWidth]);
}

- (LTVector2)remapFrameWidth:(CGFloat)frameWidth {
  CGFloat ratio = [self aspectRatio];
  LTVector2 width;
  if (ratio < 1) {
    width = LTVector2(frameWidth, frameWidth * ratio);
  } else {
    width = LTVector2(frameWidth / ratio, frameWidth);
  }
  // This fine-tuning parameter reduces the changes in the width of the frame, so the range of the
  // movement will feel more natural.
  static const CGFloat kFrameWidthScaling = 0.07;
  return width * kFrameWidthScaling;
}

- (void)setLightLeakRotation:(LTLightLeakRotation)lightLeakRotation {
  _lightLeakRotation = lightLeakRotation;
  CGFloat rotation;
  switch (lightLeakRotation) {
    case LTLightLeakRotation0:
      rotation = 0;
      break;
    case LTLightLeakRotation90:
      rotation = M_PI_2;
      break;
    case LTLightLeakRotation180:
      rotation = M_PI;
      break;
    case LTLightLeakRotation270:
      rotation = M_PI + M_PI_2;
      break;
  }
  GLKMatrix2 rotationMatrix = GLKMatrix2MakeRotation(-rotation);
  self[[LTAnalogFilmVsh lightLeakRotation]] = $(rotationMatrix);
}

@end
