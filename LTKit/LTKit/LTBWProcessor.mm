// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTBWProcessor.h"

#import "LTCLAHEProcessor.h"
#import "LTColorConversionProcessor.h"
#import "LTColorGradient.h"
#import "LTCurve.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTProceduralVignetting.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTBWProcessorFsh.h"
#import "LTShaderStorage+LTBWProcessorVsh.h"
#import "LTTexture+Factory.h"

@interface LTBWProcessor ()

/// If \c YES, the vignette processor should run at the next processing round of this processor.
@property (nonatomic) BOOL vignetteProcessorInputChanged;

/// Processor for generating the vignette texture.
@property (strong, nonatomic) LTProceduralVignetting *vignetteProcessor;

/// Mat that stores color gradient in rgb channels. Alpha channel is unused.
@property (nonatomic) cv::Mat4b colorGradientMat;

/// Identity curve, used to obtain current color gradient mapping by interpolating with
/// colorGradientMat using colorGradientIntensity as time parameter.
@property (nonatomic) cv::Mat4b identityColorGradientMat;

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
@property (nonatomic) NSUInteger detailsTextureGenerationID;

@end

@implementation LTBWProcessor

@synthesize grainTexture = _grainTexture;
@synthesize frameTexture = _frameTexture;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  LTTexture *vignetteTexture = [self createVignettingTextureWithInput:input];
  self.vignetteProcessor = [[LTProceduralVignetting alloc] initWithOutput:vignetteTexture];
  NSDictionary *auxiliaryTextures =
      @{[LTBWProcessorFsh grainTexture]: [self defaultGrainTexture],
        [LTBWProcessorFsh vignettingTexture]: vignetteTexture,
        [LTBWProcessorFsh frameTexture]: [self defaultFrameTexture]};
  if (self = [super initWithVertexSource:[LTBWProcessorVsh source]
                          fragmentSource:[LTBWProcessorFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    self.identityColorGradientMat = [[LTColorGradient identityGradient] matWithSamplingPoints:256];
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

- (LTTexture *)defaultFrameTexture {
  return [self greyTexture];
}

// Grey texture is neutral in overlay blending mode.
- (LTTexture *)greyTexture {
  LTTexture *greyTexture = [LTTexture byteRedTextureWithSize:CGSizeMake(1, 1)];
  [greyTexture clearWithColor:LTVector4(0.5, 0.5, 0.5, 1.0)];
  return greyTexture;
}

- (LTTexture *)createVignettingTextureWithInput:(LTTexture *)input {
  static const CGFloat kVignettingMaxDimension = 256;
  CGSize vignettingSize = CGScaleDownToDimension(input.size, kVignettingMaxDimension);
  LTTexture *vignetteTexture = [LTTexture byteRedTextureWithSize:vignettingSize];
  return vignetteTexture;
}

- (void)updateDetailsTextureIfNecessary {
  if (self.detailsTextureGenerationID != self.inputTexture.generationID ||
      !self.auxiliaryTextures[[LTBWProcessorFsh detailsTexture]]) {
    self.detailsTextureGenerationID = self.inputTexture.generationID;
    [self setAuxiliaryTexture:[self createDetailsTexture:self.inputTexture]
                     withName:[LTBWProcessorFsh detailsTexture]];
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
      @instanceKeypath(LTBWProcessor, brightness),
      @instanceKeypath(LTBWProcessor, contrast),
      @instanceKeypath(LTBWProcessor, exposure),
      @instanceKeypath(LTBWProcessor, offset),
      @instanceKeypath(LTBWProcessor, structure),
       
      @instanceKeypath(LTBWProcessor, colorFilter),
      @instanceKeypath(LTBWProcessor, colorGradient),
      @instanceKeypath(LTBWProcessor, colorGradientIntensity),
      @instanceKeypath(LTBWProcessor, colorGradientFade),
       
      @instanceKeypath(LTBWProcessor, grainTexture),
      @instanceKeypath(LTBWProcessor, grainChannelMixer),
      @instanceKeypath(LTBWProcessor, grainAmplitude),
       
      @instanceKeypath(LTBWProcessor, vignetteIntensity),
      @instanceKeypath(LTBWProcessor, vignetteSpread),
      @instanceKeypath(LTBWProcessor, vignetteCorner),
      @instanceKeypath(LTBWProcessor, vignetteTransition),

      @instanceKeypath(LTBWProcessor, frameTexture),
      @instanceKeypath(LTBWProcessor, frameWidth)
    ]];
  });
  
  return properties;
}

+ (BOOL)isPassthroughForDefaultInputModel {
  return NO;
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)preprocess {
  [self updateDetailsTextureIfNecessary];
  
  [self runSubProcessors];
  [self updateLUT];
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

- (void)setNeedsToneLUTUpdate {
  self.shouldUpdateToneLUT = YES;
}

- (void)updateLUT {
  if (self.shouldUpdateToneLUT) {
    [self updateToneLUT];
    self.shouldUpdateToneLUT = NO;
  }
}

#pragma mark -
#pragma mark Tone
#pragma mark -

LTPropertyWithoutSetter(LTVector3, colorFilter, ColorFilter, -2 * LTVector3One, 2 * LTVector3One,
                        LTVector3(0.299, 0.587, 0.114));
- (void)setColorFilter:(LTVector3)colorFilter {
  [self _verifyAndSetColorFilter:colorFilter];
  LTParameterAssert(colorFilter.sum(), @"Black is not a valid color filter");
  self[[LTBWProcessorFsh colorFilter]] = $(_colorFilter);
}

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
  self[[LTBWProcessorFsh structure]] = @(structure);
}

#pragma mark -
#pragma mark Color Gradient
#pragma mark -

- (void)setColorGradient:(LTColorGradient *)colorGradient {
  _colorGradient = colorGradient;
  self.colorGradientMat = [colorGradient matWithSamplingPoints:256];
  [self setNeedsToneLUTUpdate];
}

LTPropertyWithoutSetter(CGFloat, colorGradientIntensity, ColorGradientIntensity, 0, 1, 1);
- (void)setColorGradientIntensity:(CGFloat)colorGradientIntensity {
  [self _verifyAndSetColorGradientIntensity:colorGradientIntensity];
  [self setNeedsToneLUTUpdate];
}

#pragma mark -
#pragma mark Curve
#pragma mark -

- (void)updateToneLUT {
  static const ushort kLutSize = 256;

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

  cv::Mat1b toneCurve(1, kLutSize);
  cv::LUT((1.0 - contrast) * [LTCurve identity] + contrast * contrastCurve,
          (1.0 - brightness) * [LTCurve identity] + brightness * brightnessCurve,
          toneCurve);
  toneCurve = toneCurve * std::pow(2.0, self.exposure) + self.offset * 255;

  LTTexture *target = self.shouldUseColorGradientTextureB ?
      self.colorGradientTextureB : self.colorGradientTextureA;
  [target mappedImageForWriting:^(cv::Mat *mapped, BOOL) {
    cv::Mat4b colorCurve;
    cv::addWeighted(self.identityColorGradientMat, 1 - self.colorGradientIntensity,
                    self.colorGradientMat, self.colorGradientIntensity, 0, colorCurve);
    
    cv::Mat mixIn[] = {colorCurve, toneCurve};
    int fromTo[] = {0, 0, 1, 1, 2, 2, 4, 3};
  
    cv::mixChannels(mixIn, 2, mapped, 1, fromTo, 4);
  }];

  [self setAuxiliaryTexture:target withName:[LTBWProcessorFsh colorGradient]];
  self.shouldUseColorGradientTextureB = !self.shouldUseColorGradientTextureB;
}

LTPropertyWithoutSetter(CGFloat, colorGradientFade, ColorGradientFade, 0, 1, 0);
- (void)setColorGradientFade:(CGFloat)colorGradientFade {
  [self _verifyAndSetColorGradientFade:colorGradientFade];
  self[[LTBWProcessorFsh colorGradientFade]] = @(colorGradientFade);
}

#pragma mark -
#pragma mark Vignette
#pragma mark -

LTPropertyWithoutSetter(CGFloat, vignetteIntensity, VignetteIntensity, -1, 1, 0);
- (void)setVignetteIntensity:(CGFloat)vignetteIntensity {
  [self _verifyAndSetVignetteIntensity:vignetteIntensity];
  // // Remap [-1, 1] -> [0.0 1.0].
  CGFloat remap = (1.0 + vignetteIntensity) / 2.0;
  self[[LTBWProcessorFsh vignetteIntensity]] = @(remap);
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
  [self setAuxiliaryTexture:grainTexture withName:[LTBWProcessorFsh grainTexture]];
  [self setupGrainTextureScalingWithOutputSize:self.outputSize grain:self.grainTexture];
}

- (BOOL)isValidGrainTexture:(LTTexture *)texture {
  BOOL isTilable = LTIsPowerOfTwo(texture.size) && (texture.wrap == LTTextureWrapRepeat);
  BOOL matchesOutputSize = (texture.size == self.outputSize);
  return isTilable || matchesOutputSize;
}

- (void)setupGrainTextureScalingWithOutputSize:(CGSize)size grain:(LTTexture *)grain {
  self[[LTBWProcessorVsh grainScaling]] = $(LTVector2(size / grain.size));
}

LTPropertyWithoutSetter(LTVector3, grainChannelMixer, GrainChannelMixer,
                        LTVector3Zero, LTVector3One, LTVector3(1, 0, 0));
- (void)setGrainChannelMixer:(LTVector3)grainChannelMixer {
  [self _verifyAndSetGrainChannelMixer:grainChannelMixer];
  _grainChannelMixer = grainChannelMixer / grainChannelMixer.sum();
  self[[LTBWProcessorFsh grainChannelMixer]] = $(_grainChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, grainAmplitude, GrainAmplitude, 0, 1, 1);
- (void)setGrainAmplitude:(CGFloat)grainAmplitude {
  [self _verifyAndSetGrainAmplitude:grainAmplitude];
  self[[LTBWProcessorFsh grainAmplitude]] = @(grainAmplitude);
}

#pragma mark -
#pragma mark Frame
#pragma mark -

- (LTTexture *)frameTexture {
  if (!_frameTexture) {
    _frameTexture = [self defaultFrameTexture];
  }
  return _frameTexture;
}

- (void)setFrameTexture:(LTTexture *)frameTexture {
  if (!frameTexture) {
    frameTexture = [self defaultFrameTexture];
  }
  _frameTexture = frameTexture;
  [self setAuxiliaryTexture:frameTexture withName:[LTBWProcessorFsh frameTexture]];
  [self updateAspectRatioWithFrameTexture:frameTexture];
}

- (void)updateAspectRatioWithFrameTexture:(LTTexture *)frameTexture {
  CGFloat frameAspectRatio = frameTexture.size.width / frameTexture.size.height;
  CGFloat imageAspectRatio = [self aspectRatio];
  CGFloat combinedAspectRatio;
  CGFloat flipFrameCoordinates;
  if ((frameAspectRatio > 1 && imageAspectRatio < 1) ||
      (frameAspectRatio < 1 && imageAspectRatio > 1)) {
    combinedAspectRatio = imageAspectRatio * frameAspectRatio;
    flipFrameCoordinates = 1;
  } else {
    combinedAspectRatio = imageAspectRatio / frameAspectRatio;
    flipFrameCoordinates = 0;
  }
  self[[LTBWProcessorFsh combinedAspectRatio]] = @(combinedAspectRatio);
  self[[LTBWProcessorFsh flipFrameCoordinates]] = @(flipFrameCoordinates);
}

- (BOOL)isValidFrameTexture:(LTTexture *)texture {
  return texture.size.width == texture.size.height;
}

LTPropertyWithoutSetter(CGFloat, frameWidth, FrameWidth, -1, 1, 0);
- (void)setFrameWidth:(CGFloat)frameWidth {
  [self _verifyAndSetFrameWidth:frameWidth];
  self[[LTBWProcessorFsh frameWidth]] = $([self remapFrameWidth:frameWidth]);
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

@end
