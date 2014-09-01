// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Zeev Farbman.

#import "LTProceduralVignetting.h"

#import "LTGLKitExtensions.h"
#import "LTGPUImageProcessor+Protected.h"
#import "LTProgram.h"
#import "LTShaderStorage+LTProceduralVignettingFsh.h"
#import "LTShaderStorage+LTPassthroughShaderVsh.h"
#import "LTTexture+Factory.h"

@implementation LTProceduralVignetting

- (instancetype)initWithOutput:(LTTexture *)output { 
  LTTexture *defaultNoise = [self createNeutralNoise];
  NSDictionary *auxiliaryTextures = @{[LTProceduralVignettingFsh noiseTexture]: defaultNoise};
  
  if (self = [super initWithVertexSource:[LTPassthroughShaderVsh source]
                          fragmentSource:[LTProceduralVignettingFsh source] sourceTexture:output
                       auxiliaryTextures:auxiliaryTextures
                          andOutput:output]) {
    [self setDefaultValues];
    [self precomputeDistanceShift:output.size];
  }
  return self;
}

- (void)setDefaultValues {
  self.corner = self.defaultCorner;
  self.spread = self.defaultSpread;
  self.noiseAmplitude = self.defaultNoiseAmplitude;
  self.noiseChannelMixer = self.defaultNoiseChannelMixer;
  self.noise = nil;
}

- (LTTexture *)createNeutralNoise {
  cv::Mat4b input(1, 1, cv::Vec4b(128, 128, 128, 255));
  return [LTTexture textureWithImage:input];
}

// Precompute the distance shift that is used to correct aspect ratio in the shader.
// Aspect ratio is corrected by zeroing the longer dimension near the center, so non-zero part
// of both dimensions is equal. Such strategy (instead of simple scaling) is needed in order to
// preserve the correct transition behaviour.
- (void)precomputeDistanceShift:(CGSize)size {
  LTVector2 distanceShift;
  if (size.width > size.height) {
    distanceShift = LTVector2(1.0 - size.height / size.width, 0.0);
  } else {
    distanceShift = LTVector2(0.0, 1.0 - size.width / size.height);
  }
  self[[LTProceduralVignettingFsh distanceShift]] = $(distanceShift);
}

LTPropertyWithoutSetter(CGFloat, spread, Spread, 0, 100, 100);
- (void)setSpread:(CGFloat)spread {
  [self _verifyAndSetSpread:spread];
  self[[LTProceduralVignettingFsh spread]] = @(spread / 100.0);
}

LTPropertyWithoutSetter(CGFloat, corner, Corner, 2, 16, 2);
- (void)setCorner:(CGFloat)corner {
  [self _verifyAndSetCorner:corner];
  self[[LTProceduralVignettingFsh corner]] = @(corner);
}

- (void)setNoise:(LTTexture *)noise {
  if (!noise) {
    _noise = [self createNeutralNoise];
  } else {
    _noise = noise;
  }
  [self setAuxiliaryTexture:_noise withName:[LTProceduralVignettingFsh noiseTexture]];
}

LTPropertyWithoutSetter(LTVector3, noiseChannelMixer, NoiseChannelMixer,
                        -LTVector3One, LTVector3One, LTVector3(1, 0, 0));
- (void)setNoiseChannelMixer:(LTVector3)noiseChannelMixer {
  [self _verifyAndSetNoiseChannelMixer:noiseChannelMixer];
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / noiseChannelMixer.sum();
  self[[LTProceduralVignettingFsh noiseChannelMixer]] = $(_noiseChannelMixer);
}

LTPropertyWithoutSetter(CGFloat, noiseAmplitude, NoiseAmplitude, 0, 100, 0);
- (void)setNoiseAmplitude:(CGFloat)noiseAmplitude {
  [self _verifyAndSetNoiseAmplitude:noiseAmplitude];
  self[[LTProceduralVignettingFsh noiseAmplitude]] = @(noiseAmplitude);
}

@end
