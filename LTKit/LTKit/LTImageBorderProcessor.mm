// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTImageBorderProcessor.h"

#import "LTCGExtensions.h"
#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTMathUtils.h"
#import "LTOpenCVExtensions.h"
#import "LTProceduralFrameProcessor.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTShaderStorage+LTImageBorderFsh.h"
#import "LTTexture+Factory.h"

@interface LTImageBorderProcessor ()

/// If \c YES, the outer frame processor should run at the next processing round of this processor.
@property (nonatomic) BOOL outerFrameProcessorInputChanged;

/// If \c YES, the inner frame processor should run at the next processing round of this processor.
@property (nonatomic) BOOL innerFrameProcessorInputChanged;

// Frame that is used to create an outer part of the image border.
@property (strong, nonatomic) LTProceduralFrameProcessor *outerFrameProcessor;

// Frame that is used to create an inner part of the image border.
@property (strong, nonatomic) LTProceduralFrameProcessor *innerFrameProcessor;

// Texture that stores the result of outerFrameProcessor.
@property (strong, nonatomic) LTTexture *outerFrameTexture;

// Texture that stores the result of innerFrameProcessor.
@property (strong, nonatomic) LTTexture *innerFrameTexture;

@end

@implementation LTImageBorderProcessor

static const CGFloat kFrameMaxDimension = 1024;

- (instancetype)initWithInput:(LTTexture *)input output:(LTTexture *)output {
  [self initializeFramesWithInput:input];
  NSDictionary *auxiliaryTextures =
    @{[LTImageBorderFsh outerFrameTexture]: self.outerFrameTexture,
      [LTImageBorderFsh innerFrameTexture]: self.innerFrameTexture};
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTImageBorderFsh source] sourceTexture:input
                       auxiliaryTextures:auxiliaryTextures andOutput:output]) {
    [self setDefaultValues];
    [self setNeedsSubProcessing];
  }
  return self;
}

- (void)initializeFramesWithInput:(LTTexture *)input {
  // Setup outer frame.
  self.outerFrameTexture = [self createFrameTextureWithInput:input];
  self.outerFrameProcessor =
      [[LTProceduralFrameProcessor alloc] initWithOutput:self.outerFrameTexture];
  
  // Setup inner frame.
  self.innerFrameTexture = [self createFrameTextureWithInput:input];
  self.innerFrameProcessor =
      [[LTProceduralFrameProcessor alloc] initWithOutput:self.innerFrameTexture];
}

- (void)setDefaultValues {
  // As long as default roughness value is 1, no need to run the setter.
  _roughness = self.defaultRoughness;
}

- (LTTexture *)createFrameTextureWithInput:(LTTexture *)input {
  CGSize frameSize = CGScaleDownToDimension(input.size, kFrameMaxDimension);
  return [LTTexture byteRGBATextureWithSize:frameSize];
}

#pragma mark -
#pragma mark Processing
#pragma mark -

- (void)setNeedsSubProcessing {
  [self setNeedsOuterFrameProcessing];
  [self setNeedsInnerFrameProcessing];
}

- (void)setNeedsOuterFrameProcessing {
  self.outerFrameProcessorInputChanged = YES;
}

- (void)setNeedsInnerFrameProcessing {
  self.innerFrameProcessorInputChanged = YES;
}

- (void)preprocess {
  if (self.outerFrameProcessorInputChanged) {
    [self.outerFrameProcessor process];
    self.outerFrameProcessorInputChanged = NO;
  }
  if (self.innerFrameProcessorInputChanged) {
    [self.innerFrameProcessor process];
    self.innerFrameProcessorInputChanged = NO;
  }
}

#pragma mark -
#pragma mark Both Frames
#pragma mark -

LTPropertyWithoutSetter(CGFloat, roughness, Roughness, -1, 1, 0);
- (void)setRoughness:(CGFloat)roughness {
  [self _verifyAndSetRoughness:roughness];
  // Update outer frame noise amplitude.
  self.outerFrameProcessor.noiseAmplitude *= [self noiseScalingWithRoughness:roughness];
  [self.outerFrameProcessor process];
  // Update inner frame noise amplitude.
  self.innerFrameProcessor.noiseAmplitude *= [self noiseScalingWithRoughness:roughness];
  [self.innerFrameProcessor process];
}

static const CGFloat kNoiseScalingBase = 10;

- (CGFloat)noiseScalingWithRoughness:(CGFloat)roughness {
  return powf(kNoiseScalingBase, roughness);
}

#pragma mark -
#pragma mark Outer Frame
#pragma mark -

LTPropertyProxyWithoutSetter(CGFloat, outerFrameWidth, OuterFrameWidth,
                             self.outerFrameProcessor, width, Width);
- (void)setOuterFrameWidth:(CGFloat)outerFrameWidth {
  // Update the dependent inner frame.
  _innerFrameWidth = outerFrameWidth + self.innerFrameWidth - self.outerFrameWidth;
  self.innerFrameProcessor.width = _innerFrameWidth;
  [self setNeedsInnerFrameProcessing];
  // Update outer frame.
  self.outerFrameProcessor.width = outerFrameWidth;
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
  [self setNeedsOuterFrameProcessing];
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

- (void)setOuterFrameNoiseAmplitude:(CGFloat)outerFrameNoiseAmplitude {
  self.outerFrameProcessor.noiseAmplitude = outerFrameNoiseAmplitude *
      [self noiseScalingWithRoughness:self.roughness];
  [self setNeedsOuterFrameProcessing];
}

- (CGFloat)outerFrameNoiseAmplitude {
  return self.outerFrameProcessor.noiseAmplitude / [self noiseScalingWithRoughness:self.roughness];
}

- (CGFloat)minOuterFrameNoiseAmplitude {
  return 0;
}

- (CGFloat)maxOuterFrameNoiseAmplitude {
  return 100;
}

- (CGFloat)defaultOuterFrameNoiseAmplitude {
  return 0;
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
  LTParameterAssert(self.outerFrameWidth + innerFrameWidth <= self.innerFrameProcessor.maxWidth,
                    @"Sum of outer and inner width is above maximum value.");
  _innerFrameWidth = self.outerFrameWidth + innerFrameWidth;
  self.innerFrameProcessor.width = _innerFrameWidth;
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
  [self setNeedsInnerFrameProcessing];
}

LTPropertyProxyWithoutSetter(LTVector3, innerFrameNoiseChannelMixer, InnerFrameNoiseChannelMixer,
                             self.innerFrameProcessor, noiseChannelMixer, NoiseChannelMixer);
- (void)setInnerFrameNoiseChannelMixer:(LTVector3)innerFrameNoiseChannelMixer {
  self.innerFrameProcessor.noiseChannelMixer = innerFrameNoiseChannelMixer;
  [self.innerFrameProcessor process];
}

- (void)setInnerFrameNoiseAmplitude:(CGFloat)innerFrameNoiseAmplitude {
  self.innerFrameProcessor.noiseAmplitude = innerFrameNoiseAmplitude *
      [self noiseScalingWithRoughness:self.roughness];
  [self setNeedsInnerFrameProcessing];
}

- (CGFloat)innerFrameNoiseAmplitude {
  return self.innerFrameProcessor.noiseAmplitude / [self noiseScalingWithRoughness:self.roughness];
}

- (CGFloat)minInnerFrameNoiseAmplitude {
  return 0;
}

- (CGFloat)maxInnerFrameNoiseAmplitude {
  return 100;
}

- (CGFloat)defaultInnerFrameNoiseAmplitude {
  return 0;
}

LTPropertyProxyWithoutSetter(LTVector3, innerFrameColor, InnerFrameColor,
                             self.innerFrameProcessor, color, Color);
- (void)setInnerFrameColor:(LTVector3)innerFrameColor {
  self.innerFrameProcessor.color = innerFrameColor;
  [self setNeedsInnerFrameProcessing];
}

@end
