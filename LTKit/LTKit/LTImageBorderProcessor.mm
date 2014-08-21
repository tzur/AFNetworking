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

// Returns YES if subprocessors used by this class are initialized, NO otherwise.
@property (nonatomic) BOOL subProcessorsInitialized;

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

- (void)initializeSubProcessors {
  [self.outerFrameProcessor process];
  [self.innerFrameProcessor process];
  self.subProcessorsInitialized = YES;
}

- (void)process {
  if (!self.subProcessorsInitialized) {
    [self initializeSubProcessors];
  }
  return [super process];
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

- (void)setOuterFrameWidth:(CGFloat)outerFrameWidth {
  // Update the dependent inner frame.
  _innerFrameWidth = outerFrameWidth + self.innerFrameWidth - self.outerFrameWidth;
  self.innerFrameProcessor.width = _innerFrameWidth;
  [self.innerFrameProcessor process];
  // Update outer frame.
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
  self.outerFrameProcessor.noise = outerFrameNoise;
}

- (LTTexture *)outerFrameNoise {
  return self.outerFrameProcessor.noise;
}

- (void)setOuterFrameNoiseChannelMixer:(LTVector3)outerFrameNoiseChannelMixer {
  self.outerFrameProcessor.noiseChannelMixer = outerFrameNoiseChannelMixer;
  [self.outerFrameProcessor process];
}

- (LTVector3)outerFrameNoiseChannelMixer {
  return self.outerFrameProcessor.noiseChannelMixer;
}

- (void)setOuterFrameNoiseAmplitude:(CGFloat)outerFrameNoiseAmplitude {
  self.outerFrameProcessor.noiseAmplitude = outerFrameNoiseAmplitude *
      [self noiseScalingWithRoughness:self.roughness];
  [self.outerFrameProcessor process];
}

- (CGFloat)outerFrameNoiseAmplitude {
  return self.outerFrameProcessor.noiseAmplitude / [self noiseScalingWithRoughness:self.roughness];
}

- (void)setOuterFrameColor:(LTVector3)outerFrameColor {
  self.outerFrameProcessor.color = outerFrameColor;
  [self.outerFrameProcessor process];
}

- (LTVector3)outerFrameColor {
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
  self.innerFrameProcessor.noise = innerFrameNoise;
  [self.innerFrameProcessor process];
}

- (LTTexture *)innerFrameNoise {
  return self.innerFrameProcessor.noise;
}

- (void)setInnerFrameNoiseChannelMixer:(LTVector3)innerFrameNoiseChannelMixer {
  self.innerFrameProcessor.noiseChannelMixer = innerFrameNoiseChannelMixer;
  [self.innerFrameProcessor process];
}

- (LTVector3)innerFrameNoiseChannelMixer {
  return self.innerFrameProcessor.noiseChannelMixer;
}

- (void)setInnerFrameNoiseAmplitude:(CGFloat)innerFrameNoiseAmplitude {
  self.innerFrameProcessor.noiseAmplitude = innerFrameNoiseAmplitude *
      [self noiseScalingWithRoughness:self.roughness];
  [self.innerFrameProcessor process];
}

- (CGFloat)innerFrameNoiseAmplitude {
  return self.innerFrameProcessor.noiseAmplitude / [self noiseScalingWithRoughness:self.roughness];
}

- (void)setInnerFrameColor:(LTVector3)innerFrameColor {
  self.innerFrameProcessor.color = innerFrameColor;
  [self.innerFrameProcessor process];
}

- (LTVector3)innerFrameColor {
  return self.innerFrameProcessor.color;
}

@end
