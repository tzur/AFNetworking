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
  LTProgram *program =
      [[LTProgram alloc] initWithVertexSource:[LTPassthroughShaderVsh source]
                               fragmentSource:[LTProceduralVignettingFsh source]];
  
  LTTexture *defaultNoise = [self createNeutralNoise];
  NSDictionary *auxiliaryTextures = @{[LTProceduralVignettingFsh noiseTexture]: defaultNoise};
  
  if (self = [super initWithProgram:program sourceTexture:output auxiliaryTextures:auxiliaryTextures
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
  GLKVector2 distanceShift;
  if (size.width > size.height) {
    distanceShift = GLKVector2Make(1.0 - size.height / size.width, 0.0);
  } else {
    distanceShift = GLKVector2Make(0.0, 1.0 - size.width / size.height);
  }
  self[[LTProceduralVignettingFsh distanceShift]] = $(distanceShift);
}

LTPropertyWithSetter(CGFloat, spread, Spread, 0, 100, 100, ^{
  self[[LTProceduralVignettingFsh spread]] = @(spread / 100.0);
});

LTPropertyWithSetter(CGFloat, corner, Corner, 2, 16, 2, ^{
  self[[LTProceduralVignettingFsh corner]] = @(corner);
});

- (void)setNoise:(LTTexture *)noise {
  if (!noise) {
    _noise = [self createNeutralNoise];
  } else {
    _noise = noise;
  }
  [self setAuxiliaryTexture:_noise withName:[LTProceduralVignettingFsh noiseTexture]];
}

LTPropertyWithSetter(GLKVector3, noiseChannelMixer, NoiseChannelMixer,
                     -GLKVector3One, GLKVector3One, GLKVector3Make(1, 0, 0), ^{
  // Normalize the input, so mixing doesn't affect amplitude.
  _noiseChannelMixer = noiseChannelMixer / std::sum(noiseChannelMixer);
  self[[LTProceduralVignettingFsh noiseChannelMixer]] = $(_noiseChannelMixer);
});

LTPropertyWithSetter(CGFloat, noiseAmplitude, NoiseAmplitude, 0, 100, 0, ^{
  self[[LTProceduralVignettingFsh noiseAmplitude]] = @(noiseAmplitude);
});

@end
